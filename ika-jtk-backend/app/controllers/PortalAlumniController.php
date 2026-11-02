<?php
namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Alumni;

class PortalAlumniController extends Controller
{
    public function index()
    {
        $page = $this->request->getQuery('page', 'int');
        $limit = $this->request->getQuery('limit', 'int', 12);
        $search = trim($this->request->getQuery('search', 'string', ''));
        $angkatan = trim($this->request->getQuery('angkatan', 'string', ''));
        $hasGrafis = $this->request->getQuery('hasGrafis', 'string', 'false');

        $conditions = "deletedAt IS NULL AND (status = 'ACTIVE' OR status = 'APPROVED')";
        $bind = [];

        if ($hasGrafis === 'true') {
            $conditions .= " AND alumniGrafis IS NOT NULL AND CAST(alumniGrafis AS text) <> '' AND CAST(alumniGrafis AS text) <> 'null' AND CAST(alumniGrafis AS text) <> '{}' AND (CAST(alumniGrafis AS text) LIKE '%\"status\":\"APPROVED\"%' OR CAST(alumniGrafis AS text) LIKE '%\"status\": \"APPROVED\"%')";
        }

        if ($page !== null) {
            if ($search !== '') {
                $conditions .= " AND (LOWER(nama) LIKE LOWER(:search_start:) OR LOWER(nama) LIKE LOWER(:search_space:))";
                $bind['search_start'] = $search . '%';
                $bind['search_space'] = '% ' . $search . '%';
            }
            if ($angkatan !== '' && $angkatan !== 'Semua') {
                $conditions .= " AND angkatan = :angkatan:";
                $bind['angkatan'] = $angkatan;
            }

            $total = \App\Models\Alumni::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $offset = ($page - 1) * $limit;
            
            $list = \App\Models\Alumni::find([
                'conditions' => $conditions,
                'bind' => $bind,
                'order' => 'nama ASC',
                'limit' => $limit,
                'offset' => $offset
            ]);

            $angkatanList = \App\Models\Alumni::find([
                'columns' => 'DISTINCT angkatan',
                'conditions' => "deletedAt IS NULL AND (status = 'ACTIVE' OR status = 'APPROVED')",
                'order' => 'angkatan ASC'
            ]);
            $angkatanOpts = [];
            foreach ($angkatanList as $a) {
                if (!empty($a->angkatan)) {
                    $angkatanOpts[] = (string)$a->angkatan;
                }
            }

            $result = [];
            foreach ($list as $item) {
                $formatted = $this->format($item);
                if ($hasGrafis === 'true' && empty($formatted['alumniGrafis'])) {
                    continue;
                }
                $result[] = $formatted;
            }

            $this->response->setStatusCode(200);
            return [
                'data' => $result,
                'total' => $total,
                'page' => $page,
                'limit' => $limit,
                'angkatanOpts' => $angkatanOpts
            ];
        }

        // Backward compatibility mode
        $list = \App\Models\Alumni::find([
            'conditions' => $conditions,
            'order' => 'nama ASC'
        ]);

        $result = [];
        foreach ($list as $item) {
            $formatted = $this->format($item);
            if ($hasGrafis === 'true' && empty($formatted['alumniGrafis'])) {
                continue;
            }
            $result[] = $formatted;
        }
        $this->response->setStatusCode(200);
        return $result;
    }

    public function show($id)
    {
        $item = Alumni::findFirst([
            'conditions' => "deletedAt IS NULL AND id = ?0 AND (status = 'ACTIVE' OR status = 'APPROVED')",
            'bind' => [$id]
        ]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Alumni tidak ditemukan.'];
        }
        $this->response->setStatusCode(200);
        return $this->formatDetail($item);
    }

    private function format($item)
    {
        $data = $item->toArray();
        $pekerjaan = $this->parseJson($data['pekerjaan'] ?? []);
        $firstJob = $pekerjaan[0] ?? null;

        $alumniGrafis = is_string($data['alumniGrafis'] ?? null) ? json_decode($data['alumniGrafis'], true) : ($data['alumniGrafis'] ?? null);
        
        // Only show alumni grafis if status is APPROVED
        if ($alumniGrafis && ($alumniGrafis['status'] ?? '') !== 'APPROVED') {
            $alumniGrafis = null;
        }
        
        if ($alumniGrafis && isset($alumniGrafis['kategori'])) {
            $kategori = strtolower($alumniGrafis['kategori']);
            $grafisId = $alumniGrafis['id'] ?? '';
            $desc = '';
            
            if (strpos($kategori, 'prestasi') !== false) {
                $prestasi = $this->parseJson($data['prestasi'] ?? []);
                foreach ($prestasi as $p) {
                    if (($p['id'] ?? '') === $grafisId) {
                        $desc = $p['judul'] ?? '';
                        break;
                    }
                }
            } else {
                foreach ($pekerjaan as $p) {
                    if (($p['id'] ?? '') === $grafisId) {
                        $job = trim($p['pekerjaan'] ?? '');
                        $company = trim($p['perusahaan'] ?? '');
                        if ($job && $company) {
                            $desc = "$job di $company";
                        } else {
                            $desc = $job ?: $company;
                        }
                        break;
                    }
                }
            }
            $alumniGrafis['description'] = $desc;
        }

        $avatarUrl = trim($data['avatarUrl'] ?? '');
        if (empty($avatarUrl)) {
            $candidate = \App\Models\Candidate::findFirst([
                'conditions' => "alumniId = ?0 AND fotoUrl IS NOT NULL AND CAST(fotoUrl AS text) <> '' AND deletedAt IS NULL",
                'bind' => [$data['id']],
                'order' => 'id DESC'
            ]);
            if ($candidate) {
                $avatarUrl = trim($candidate->fotoUrl ?? '');
            }
        }

        return [
            'id' => $data['id'],
            'noAlumni' => $data['noAlumni'] ?? null,
            'nama' => $data['nama'],
            'angkatan' => $data['angkatan'],
            'avatarUrl' => $avatarUrl,
            'keanggotaan' => $data['keanggotaan'] ?? 'Alumni',
            'posisiSekarang' => $firstJob['pekerjaan'] ?? '',
            'perusahaan' => $firstJob['perusahaan'] ?? '',
            'alumniGrafis' => $alumniGrafis,
        ];
    }

    private function formatDetail($item)
    {
        $data = $item->toArray();
        $pekerjaan = $this->parseJson($data['pekerjaan'] ?? []);
        $prestasi = $this->parseJson($data['prestasi'] ?? []);
        $firstJob = $pekerjaan[0] ?? null;

        $alumniGrafis = is_string($data['alumniGrafis'] ?? null) ? json_decode($data['alumniGrafis'], true) : ($data['alumniGrafis'] ?? null);
        if ($alumniGrafis && ($alumniGrafis['status'] ?? '') !== 'APPROVED') {
            $alumniGrafis = null;
        }

        $avatarUrl = trim($data['avatarUrl'] ?? '');
        if (empty($avatarUrl)) {
            $candidate = \App\Models\Candidate::findFirst([
                'conditions' => "alumniId = ?0 AND fotoUrl IS NOT NULL AND CAST(fotoUrl AS text) <> '' AND deletedAt IS NULL",
                'bind' => [$data['id']],
                'order' => 'id DESC'
            ]);
            if ($candidate) {
                $avatarUrl = trim($candidate->fotoUrl ?? '');
            }
        }

        $result = [
            'id' => $data['id'],
            'noAlumni' => $data['noAlumni'] ?? null,
            'nama' => $data['nama'],
            'angkatan' => $data['angkatan'],
            'avatarUrl' => $avatarUrl,
            'motto' => $data['motto'] ?? '',
            'keanggotaan' => $data['keanggotaan'] ?? 'Alumni',
            'posisiSekarang' => $firstJob['pekerjaan'] ?? '',
            'perusahaan' => $firstJob['perusahaan'] ?? '',
            'pekerjaan' => $pekerjaan,
            'prestasi' => $prestasi,
            'alumniGrafis' => $alumniGrafis,
            'linkedin' => $data['linkedin'] ?? '',
        ];

        $visibilityFields = [
            'email' => 'emailVisibility',
            'nomorHandphone' => 'nomorHandphoneVisibility',
            'alamat' => 'alamatVisibility',
        ];

        $fieldMapping = [
            'email' => 'email',
            'nomorHandphone' => 'hp',
            'alamat' => 'alamat',
        ];

        foreach ($visibilityFields as $resultKey => $visibilityKey) {
            if (($data[$visibilityKey] ?? 'private') === 'public') {
                $sourceKey = $fieldMapping[$resultKey];
                $result[$resultKey] = $data[$sourceKey] ?? '';
            }
        }

        return $result;
    }

    private function parseJson($value)
    {
        if (is_string($value)) {
            return json_decode($value, true) ?: [];
        }
        return is_array($value) ? $value : [];
    }
}
