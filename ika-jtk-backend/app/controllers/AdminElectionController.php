<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Election;
use App\Models\Candidate;
use App\Models\Alumni;
use App\Traits\CandidateFormatter;

class AdminElectionController extends Controller
{
    use CandidateFormatter;
    
    // --- ELECTION MANAGEMENT ---

    public function index()
    {
        Election::checkAndCompleteExpiredElections();
        $elections = Election::find(['conditions' => 'deletedAt IS NULL', 'order' => 'createdAt DESC']);
        $result = [];
        
        foreach ($elections as $election) {
            $data = $election->toArray();
            
            // Calculate totals
            $candidates = Candidate::find([
                'conditions' => 'electionId = ?0 AND deletedAt IS NULL',
                'bind' => [$election->id]
            ]);
            
            $data['candidates'] = [];
            $totalSuara = 0;
            foreach ($candidates as $c) {
                $data['candidates'][] = $this->formatCandidate($c->toArray());
                $totalSuara += $c->voteCount;
            }

            $data['totalSuara'] = $totalSuara;
            $data['totalVoter'] = Alumni::count([
                'conditions' => "deletedAt IS NULL AND status IN ('ACTIVE', 'APPROVED')"
            ]);

            $result[] = $data;
        }

        $this->response->setStatusCode(200);
        return $result;
    }

    public function show($id)
    {
        Election::checkAndCompleteExpiredElections();
        $election = Election::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$election) {
            $this->response->setStatusCode(404);
            return ['error' => 'Pemilu tidak ditemukan.'];
        }

        $candidates = Candidate::find([
            'conditions' => 'electionId = ?0 AND deletedAt IS NULL',
            'bind' => [$election->id],
            'order' => 'nomorUrut ASC'
        ]);

        $data = $election->toArray();
        $data['candidates'] = [];
        $totalSuara = 0;
        foreach ($candidates as $c) {
            $data['candidates'][] = $this->formatCandidate($c->toArray());
            $totalSuara += $c->voteCount;
        }
        $data['totalSuara'] = $totalSuara;
        $data['totalVoter'] = Alumni::count([
            'conditions' => "deletedAt IS NULL AND status IN ('ACTIVE', 'APPROVED')"
        ]);

        $this->response->setStatusCode(200);
        return $data;
    }

    public function summary($id)
    {
        $election = Election::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$election) {
            $this->response->setStatusCode(404);
            return ['error' => 'Pemilu tidak ditemukan.'];
        }

        $candidates = Candidate::find([
            'conditions' => 'electionId = ?0 AND deletedAt IS NULL',
            'bind' => [$election->id],
            'order' => 'nomorUrut ASC'
        ]);

        $totalSuara = 0;
        $resultKandidat = [];
        foreach ($candidates as $c) {
            $totalSuara += $c->voteCount;
            $resultKandidat[] = $this->formatCandidateSummary($c);
        }

        if ($totalSuara > 0) {
            foreach ($resultKandidat as $idx => $kItem) {
                $resultKandidat[$idx]['persentase'] = round(($kItem['voteCount'] / $totalSuara) * 100, 1);
            }
        }

        $allAlumni = Alumni::find(['conditions' => "deletedAt IS NULL AND status IN ('ACTIVE', 'APPROVED')"]);
        $angkatanCounts = [];
        $genderCounts = ['Laki-laki' => 0, 'Perempuan' => 0];

        foreach ($allAlumni as $a) {
            $angk = !empty($a->angkatan) ? (string)$a->angkatan : '2003';
            if (!isset($angkatanCounts[$angk])) {
                $angkatanCounts[$angk] = 0;
            }
            $angkatanCounts[$angk]++;

            $jk = trim((string)$a->jenisKelamin);
            if (stripos($jk, 'l') === 0 || stripos($jk, 'pria') === 0) {
                $genderCounts['Laki-laki']++;
            } elseif (stripos($jk, 'p') === 0 || stripos($jk, 'wanita') === 0) {
                $genderCounts['Perempuan']++;
            } else {
                $genderCounts['Laki-laki']++;
            }
        }

        ksort($angkatanCounts);
        $angkatanList = [];
        foreach ($angkatanCounts as $k => $v) {
            $angkatanList[] = ['angkatan' => $k, 'count' => $v];
        }

        $totalDemo = array_sum($genderCounts);
        $genderList = [];
        foreach ($genderCounts as $k => $v) {
            $genderList[] = [
                'gender' => $k,
                'count' => $v,
                'persentase' => $totalDemo > 0 ? round(($v / $totalDemo) * 100, 2) : 0
            ];
        }

        return [
            'electionId' => $election->id,
            'judul' => $election->judul,
            'status' => $election->status,
            'totalSuara' => $totalSuara,
            'totalVoter' => count($allAlumni),
            'kandidat' => $resultKandidat,
            'demographics' => [
                'angkatan' => $angkatanList,
                'gender' => $genderList,
            ]
        ];
    }

    public function create()
    {
        Election::checkAndCompleteExpiredElections();
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        
        $status = $request['status'] ?? 'Draft';
        if ($status === 'Active' || $status === 'Ongoing') {
            $now = date('Y-m-d H:i:s');
            $activeElection = Election::findFirst([
                'conditions' => 'deletedAt IS NULL AND status IN ({status:array}) AND (periodeEnd IS NULL OR periodeEnd > :now:)',
                'bind' => [
                    'status' => ['Active', 'Ongoing', 'active', 'ongoing', 'Sedang Berlangsung'],
                    'now' => $now
                ]
            ]);
            if ($activeElection) {
                $this->response->setStatusCode(400);
                return ['error' => 'Hanya satu pemilu yang dapat berlangsung dalam satu waktu.'];
            }
        }

        $periodeStart = $request['periodeStart'] ?? null;
        $periodeEnd = $request['periodeEnd'] ?? null;
        $kandidatStart = $request['kandidatStart'] ?? null;
        $kandidatEnd = $request['kandidatEnd'] ?? null;

        if ($kandidatStart && $kandidatEnd) {
            if (strtotime($kandidatEnd) <= strtotime($kandidatStart)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Periode Selesai Kandidat harus setelah atau sama dengan Periode Mulai Kandidat.'];
            }
        }
        if ($kandidatEnd && $periodeStart) {
            if (strtotime($periodeStart) < strtotime($kandidatEnd)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Periode Mulai Pemungutan Suara harus setelah atau sama dengan Periode Selesai Kandidat.'];
            }
        } elseif ($kandidatStart && $periodeStart) {
            if (strtotime($periodeStart) < strtotime($kandidatStart)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Periode Mulai Pemungutan Suara harus setelah atau sama dengan Periode Mulai Kandidat.'];
            }
        }
        $pengumumanDate = $request['pengumumanDate'] ?? null;
        $pelantikanDate = $request['pelantikanDate'] ?? null;

        if ($periodeStart && $periodeEnd) {
            $startTs = strtotime($periodeStart);
            $endTs = strtotime($periodeEnd);

            if ($endTs <= $startTs) {
                $this->response->setStatusCode(400);
                return ['error' => 'Periode Selesai Waktu Pemilihan harus setelah Periode Mulai Waktu Pemilihan.'];
            }
        }
        if ($periodeEnd && $pengumumanDate) {
            if (strtotime($pengumumanDate) < strtotime(substr($periodeEnd, 0, 10))) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal Pengumuman Hasil tidak boleh sebelum (backdate) dari Periode Selesai Waktu Pemilihan.'];
            }
        }
        if ($pengumumanDate && $pelantikanDate) {
            if (strtotime($pelantikanDate) < strtotime($pengumumanDate)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal Pelantikan Ketua Terpilih tidak boleh sebelum (backdate) dari Tanggal Pengumuman Hasil.'];
            }
        } elseif ($periodeEnd && $pelantikanDate) {
            if (strtotime($pelantikanDate) < strtotime(substr($periodeEnd, 0, 10))) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal Pelantikan Ketua Terpilih tidak boleh sebelum (backdate) dari Periode Selesai Waktu Pemilihan.'];
            }
        } elseif ($periodeStart && $pelantikanDate) {
            if (strtotime($pelantikanDate) < strtotime(substr($periodeStart, 0, 10))) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal Pelantikan Ketua Terpilih tidak boleh sebelum (backdate) dari Periode Mulai Waktu Pemilihan.'];
            }
        }

        $election = new Election();
        $election->judul = $request['judul'] ?? '';
        $election->deskripsi = $request['deskripsi'] ?? '';
        $election->periodeStart = $periodeStart;
        $election->periodeEnd = $periodeEnd;
        $election->kandidatStart = $kandidatStart;
        $election->kandidatEnd = $kandidatEnd;
        $election->pengumumanDate = $request['pengumumanDate'] ?? null;
        $election->pelantikanDate = $request['pelantikanDate'] ?? null;
        $election->status = $status;
        $election->hideStatistik = !empty($request['hideStatistik']) ? 1 : 0;

        if ($election->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menyimpan pemilu: ' . implode(', ', $election->getMessages())];
        }

        $this->response->setStatusCode(201);
        return $election->toArray();
    }

    public function update($id)
    {
        Election::checkAndCompleteExpiredElections();
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        
        $election = Election::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$election) {
            $this->response->setStatusCode(404);
            return ['error' => 'Pemilu tidak ditemukan.'];
        }

        // Lock jadwal validation
        $now = new \DateTime();
        if ($election->periodeStart) {
            $start = new \DateTime($election->periodeStart);
            if ($election->status !== 'Draft' && $now >= $start) {
                if (isset($request['periodeStart']) || isset($request['periodeEnd'])) {
                    $this->response->setStatusCode(400);
                    return ['error' => 'Jadwal pemilu tidak dapat diubah karena pemilu sudah dimulai.'];
                }
            }
        }

        $newStatus = $request['status'] ?? $election->status;
        if (($newStatus === 'Active' || $newStatus === 'Ongoing') && $newStatus !== $election->status) {
            $nowStr = date('Y-m-d H:i:s');
            $activeElection = Election::findFirst([
                'conditions' => 'deletedAt IS NULL AND status IN ({status:array}) AND id != :id: AND (periodeEnd IS NULL OR periodeEnd > :now:)',
                'bind' => [
                    'status' => ['Active', 'Ongoing', 'active', 'ongoing', 'Sedang Berlangsung'],
                    'id' => $id,
                    'now' => $nowStr
                ]
            ]);
            if ($activeElection) {
                $this->response->setStatusCode(400);
                return ['error' => 'Hanya satu pemilu yang dapat berlangsung dalam satu waktu.'];
            }
        }

        $periodeStart = $request['periodeStart'] ?? $election->periodeStart;
        $periodeEnd = $request['periodeEnd'] ?? $election->periodeEnd;
        if (($newStatus === 'Active' || $newStatus === 'Ongoing') && $newStatus !== $election->status) {
            if ($periodeStart && strtotime($periodeStart) > time()) {
                $periodeStart = date('Y-m-d H:i:s');
                $request['periodeStart'] = $periodeStart;
            }
        }
        $kandidatStart = $request['kandidatStart'] ?? $election->kandidatStart;
        $kandidatEnd = $request['kandidatEnd'] ?? $election->kandidatEnd;

        if ($kandidatStart && $kandidatEnd) {
            if (strtotime($kandidatEnd) <= strtotime($kandidatStart)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Periode Selesai Kandidat harus setelah atau sama dengan Periode Mulai Kandidat.'];
            }
        }
        if ($kandidatEnd && $periodeStart) {
            if (strtotime($periodeStart) < strtotime($kandidatEnd)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Periode Mulai Pemungutan Suara harus setelah atau sama dengan Periode Selesai Kandidat.'];
            }
        } elseif ($kandidatStart && $periodeStart) {
            if (strtotime($periodeStart) < strtotime($kandidatStart)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Periode Mulai Pemungutan Suara harus setelah atau sama dengan Periode Mulai Kandidat.'];
            }
        }
        $pengumumanDate = array_key_exists('pengumumanDate', $request) ? $request['pengumumanDate'] : $election->pengumumanDate;
        $pelantikanDate = array_key_exists('pelantikanDate', $request) ? $request['pelantikanDate'] : $election->pelantikanDate;

        if ($periodeStart && $periodeEnd) {
            $startTs = strtotime($periodeStart);
            $endTs = strtotime($periodeEnd);

            if ($endTs <= $startTs) {
                $this->response->setStatusCode(400);
                return ['error' => 'Periode Selesai Waktu Pemilihan harus setelah Periode Mulai Waktu Pemilihan.'];
            }
        }
        if ($periodeEnd && $pengumumanDate) {
            if (strtotime($pengumumanDate) < strtotime(substr($periodeEnd, 0, 10))) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal Pengumuman Hasil tidak boleh sebelum (backdate) dari Periode Selesai Waktu Pemilihan.'];
            }
        }
        if ($pengumumanDate && $pelantikanDate) {
            if (strtotime($pelantikanDate) < strtotime($pengumumanDate)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal Pelantikan Ketua Terpilih tidak boleh sebelum (backdate) dari Tanggal Pengumuman Hasil.'];
            }
        } elseif ($periodeEnd && $pelantikanDate) {
            if (strtotime($pelantikanDate) < strtotime(substr($periodeEnd, 0, 10))) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal Pelantikan Ketua Terpilih tidak boleh sebelum (backdate) dari Periode Selesai Waktu Pemilihan.'];
            }
        } elseif ($periodeStart && $pelantikanDate) {
            if (strtotime($pelantikanDate) < strtotime(substr($periodeStart, 0, 10))) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal Pelantikan Ketua Terpilih tidak boleh sebelum (backdate) dari Periode Mulai Waktu Pemilihan.'];
            }
        }

        if (isset($request['judul'])) $election->judul = $request['judul'];
        if (isset($request['deskripsi'])) $election->deskripsi = $request['deskripsi'];
        if (isset($request['periodeStart'])) $election->periodeStart = $request['periodeStart'];
        if (isset($request['periodeEnd'])) $election->periodeEnd = $request['periodeEnd'];
        if (isset($request['kandidatStart'])) $election->kandidatStart = $request['kandidatStart'];
        if (isset($request['kandidatEnd'])) $election->kandidatEnd = $request['kandidatEnd'];
        if (isset($request['pengumumanDate'])) $election->pengumumanDate = $request['pengumumanDate'];
        if (isset($request['pelantikanDate'])) $election->pelantikanDate = $request['pelantikanDate'];
        if (isset($request['status'])) $election->status = $request['status'];
        if (isset($request['hideStatistik'])) $election->hideStatistik = !empty($request['hideStatistik']) ? 1 : 0;

        if ($election->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal memperbarui pemilu: ' . implode(', ', $election->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $election->toArray();
    }

    public function delete($id)
    {
        $election = Election::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$election) {
            $this->response->setStatusCode(404);
            return ['error' => 'Pemilu tidak ditemukan.'];
        }

        if (in_array($election->status, ['Active', 'Ongoing', 'Completed', 'Closed'])) {
            $this->response->setStatusCode(400);
            return ['error' => 'Pemilu yang sudah berjalan atau selesai tidak dapat dihapus.'];
        }

        $candidates = Candidate::find([
            'conditions' => 'electionId = ?0 AND deletedAt IS NULL',
            'bind' => [$election->id]
        ]);
        foreach ($candidates as $c) {
            $c->deletedAt = date('Y-m-d H:i:s');
            if ($c->save() === false) {
                $messages = $c->getMessages();
                $this->response->setStatusCode(500);
                return ['error' => 'Gagal menghapus kandidat.', 'detail' => implode(', ', $messages)];
            }
        }

        $election->deletedAt = date('Y-m-d H:i:s');
        if ($election->save() === false) {
            $messages = $election->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus pemilu.', 'detail' => implode(', ', $messages)];
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Pemilu berhasil dihapus'];
    }

    // --- CANDIDATE MANAGEMENT ---

    public function addCandidate($electionId)
    {
        $election = Election::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$electionId]
        ]);

        if (!$election) {
            $this->response->setStatusCode(404);
            return ['error' => 'Pemilu tidak ditemukan.'];
        }

        if ($election->status !== 'Draft') {
            $this->response->setStatusCode(400);
            return ['error' => 'Kandidat hanya dapat diubah saat pemilu berstatus Draft.'];
        }

        $request = $this->request->getJsonRawBody(true);
        if (!$request) {
            $this->response->setStatusCode(400);
            return ['error' => 'Invalid JSON payload'];
        }

        $nomorUrut = $request['nomorUrut'] ?? null;
        if (!$nomorUrut) {
            $this->response->setStatusCode(400);
            return ['error' => 'Nomor urut harus diisi.'];
        }

        $existingCandidate = Candidate::findFirst([
            'conditions' => 'electionId = ?0 AND nomorUrut = ?1 AND deletedAt IS NULL',
            'bind' => [$electionId, $nomorUrut]
        ]);

        if ($existingCandidate) {
            $this->response->setStatusCode(400);
            return ['error' => 'Nomor urut kandidat tidak boleh duplikat dalam satu pemilu.'];
        }

        $alumniId = !empty($request['alumniId']) ? trim($request['alumniId']) : null;
        if ($alumniId !== null) {
            $existingAlumni = Candidate::findFirst([
                'conditions' => 'electionId = ?0 AND alumniId = ?1 AND deletedAt IS NULL',
                'bind' => [$electionId, $alumniId]
            ]);
            if ($existingAlumni) {
                $this->response->setStatusCode(400);
                return ['error' => 'Alumni ini sudah terdaftar sebagai kandidat pada pemilu ini.'];
            }
        }

        $nama = !empty($request['nama']) ? trim($request['nama']) : '';
        if ($nama !== '') {
            $existingNama = Candidate::findFirst([
                'conditions' => 'electionId = ?0 AND LOWER(nama) = ?1 AND deletedAt IS NULL',
                'bind' => [$electionId, strtolower($nama)]
            ]);
            if ($existingNama) {
                $this->response->setStatusCode(400);
                return ['error' => 'Kandidat dengan nama yang sama sudah terdaftar pada pemilu ini.'];
            }
        }

        $candidate = new Candidate();
        $candidate->electionId = $electionId;
        $candidate->alumniId = $request['alumniId'] ?? null;
        $candidate->nama = $request['nama'] ?? '';
        $candidate->angkatan = $request['angkatan'] ?? '';
        $candidate->fotoUrl = $request['fotoUrl'] ?? $request['avatarUrl'] ?? '';
        $candidate->nomorUrut = $nomorUrut;
        $candidate->visi = $request['visi'] ?? '';
        
        $candidate->misi = isset($request['misi']) && is_array($request['misi'])
            ? json_encode($request['misi'])
            : '[]';

        $candidate->pengalaman = isset($request['pengalaman']) && is_array($request['pengalaman'])
            ? json_encode($request['pengalaman'])
            : '[]';

        $candidate->programKerja = isset($request['programKerja']) && is_array($request['programKerja'])
            ? json_encode($request['programKerja'])
            : '[]';

        $candidate->prestasi = isset($request['prestasi']) && is_array($request['prestasi'])
            ? json_encode($request['prestasi'])
            : '[]';

        $candidate->tagline = isset($request['tagline']) ? trim($request['tagline']) : null;

        if ($candidate->save() === false) {
            $msg = 'Gagal menambahkan kandidat: ' . implode(', ', $candidate->getMessages());
            $this->response->setStatusCode(400);
            return ['error' => $msg];
        }

        $this->response->setStatusCode(201);
        return $candidate->toArray();
    }

    public function updateCandidate($electionId, $candidateId)
    {
        $candidate = Candidate::findFirst([
            'conditions' => 'id = ?0 AND electionId = ?1 AND deletedAt IS NULL',
            'bind' => [$candidateId, $electionId]
        ]);

        if (!$candidate) {
            $this->response->setStatusCode(404);
            return ['error' => 'Kandidat tidak ditemukan.'];
        }

        $election = Election::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$electionId]]);
        if ($election && $election->status !== 'Draft') {
            $this->response->setStatusCode(400);
            return ['error' => 'Kandidat hanya dapat diubah saat pemilu berstatus Draft.'];
        }

        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        $nomorUrut = $request['nomorUrut'] ?? $candidate->nomorUrut;

        if ($nomorUrut != $candidate->nomorUrut) {
            $existingCandidate = Candidate::findFirst([
                'conditions' => 'electionId = ?0 AND nomorUrut = ?1 AND id != ?2 AND deletedAt IS NULL',
                'bind' => [$electionId, $nomorUrut, $candidateId]
            ]);
            if ($existingCandidate) {
                $this->response->setStatusCode(400);
                return ['error' => 'Nomor urut kandidat tidak boleh duplikat dalam satu pemilu.'];
            }
        }

        $alumniId = array_key_exists('alumniId', $request) ? (!empty($request['alumniId']) ? trim($request['alumniId']) : null) : $candidate->alumniId;
        if ($alumniId !== null) {
            $existingAlumni = Candidate::findFirst([
                'conditions' => 'electionId = ?0 AND alumniId = ?1 AND id != ?2 AND deletedAt IS NULL',
                'bind' => [$electionId, $alumniId, $candidateId]
            ]);
            if ($existingAlumni) {
                $this->response->setStatusCode(400);
                return ['error' => 'Alumni ini sudah terdaftar sebagai kandidat lain pada pemilu ini.'];
            }
        }

        $nama = isset($request['nama']) ? trim($request['nama']) : $candidate->nama;
        if ($nama !== '') {
            $existingNama = Candidate::findFirst([
                'conditions' => 'electionId = ?0 AND LOWER(nama) = ?1 AND id != ?2 AND deletedAt IS NULL',
                'bind' => [$electionId, strtolower($nama), $candidateId]
            ]);
            if ($existingNama) {
                $this->response->setStatusCode(400);
                return ['error' => 'Kandidat dengan nama yang sama sudah terdaftar pada pemilu ini.'];
            }
        }

        if (array_key_exists('alumniId', $request)) $candidate->alumniId = $request['alumniId'];
        if (isset($request['nama'])) $candidate->nama = $request['nama'];
        if (isset($request['angkatan'])) $candidate->angkatan = $request['angkatan'];
        if (isset($request['fotoUrl'])) $candidate->fotoUrl = $request['fotoUrl'];
        elseif (isset($request['avatarUrl'])) $candidate->fotoUrl = $request['avatarUrl'];
        if (isset($request['nomorUrut'])) $candidate->nomorUrut = $request['nomorUrut'];
        if (isset($request['visi'])) $candidate->visi = $request['visi'];
        
        if (isset($request['misi']) && is_array($request['misi'])) {
            $candidate->misi = json_encode($request['misi']);
        }
        if (isset($request['pengalaman']) && is_array($request['pengalaman'])) {
            $candidate->pengalaman = json_encode($request['pengalaman']);
        }
        if (isset($request['programKerja']) && is_array($request['programKerja'])) {
            $candidate->programKerja = json_encode($request['programKerja']);
        }
        if (isset($request['prestasi']) && is_array($request['prestasi'])) {
            $candidate->prestasi = json_encode($request['prestasi']);
        }
        if (array_key_exists('tagline', $request)) {
            $candidate->tagline = is_string($request['tagline']) ? trim($request['tagline']) : null;
        }

        if ($candidate->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal memperbarui kandidat: ' . implode(', ', $candidate->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $candidate->toArray();
    }

    public function deleteCandidate($electionId, $candidateId)
    {
        $candidate = Candidate::findFirst([
            'conditions' => 'id = ?0 AND electionId = ?1 AND deletedAt IS NULL',
            'bind' => [$candidateId, $electionId]
        ]);

        if (!$candidate) {
            $this->response->setStatusCode(404);
            return ['error' => 'Kandidat tidak ditemukan.'];
        }

        $election = Election::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$electionId]]);
        if ($election && $election->status !== 'Draft') {
            $this->response->setStatusCode(400);
            return ['error' => 'Kandidat hanya dapat dihapus saat pemilu berstatus Draft.'];
        }

        $candidate->deletedAt = date('Y-m-d H:i:s');
        if ($candidate->save() === false) {
            $messages = $candidate->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus.', 'detail' => implode(', ', $messages)];
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Kandidat berhasil dihapus'];
    }
}
