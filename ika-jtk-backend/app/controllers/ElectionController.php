<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Election;
use App\Models\Candidate;
use App\Models\VoteRecord;
use App\Models\Alumni;
use App\Traits\CandidateFormatter;

class ElectionController extends Controller
{
    use CandidateFormatter;
    public function index()
    {
        Election::checkAndCompleteExpiredElections();
        $elections = Election::find(['conditions' => 'deletedAt IS NULL', 'order' => 'createdAt DESC']);

        $alumniId = null;
        try {
            $authHeader = $this->request->getHeader('Authorization');
            if ($authHeader && preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
                $token = $matches[1];
                $secret = $this->getDI()->get('config')['jwt_secret'];
                $decoded = \Firebase\JWT\JWT::decode($token, new \Firebase\JWT\Key($secret, 'HS256'));
                $alumniId = $decoded->id ?? null;
            }
        } catch (\Exception $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

            // Token not required for public access
        }

        $totalAlumniTerdaftar = (int) Alumni::count([
            'conditions' => "deletedAt IS NULL AND status IN ('ACTIVE', 'APPROVED')"
        ]);

        $result = [];
        foreach ($elections as $election) {
            $data = $election->toArray();

            $candidates = Candidate::find([
                'conditions' => 'deletedAt IS NULL AND electionId = ?0',
                'bind' => [$election->id],
                'order' => 'nomorUrut ASC'
            ]);

            $data['candidates'] = [];
            $totalSuara = 0;
            foreach ($candidates as $c) {
                $data['candidates'][] = $this->formatCandidate($c->toArray());
                $totalSuara += $c->voteCount;
            }
            $data['totalSuara'] = $totalSuara;
            $data['totalAlumniTerdaftar'] = $totalAlumniTerdaftar;
            $data['demographics'] = $this->getRealDemographics($election->id);

            if ($alumniId) {
                $existingVote = VoteRecord::findFirst([
                    'conditions' => 'deletedAt IS NULL AND alumniId = ?0 AND electionId = ?1',
                    'bind' => [$alumniId, $election->id]
                ]);
                $data['userHasVoted'] = $existingVote ? true : false;
            }

            $result[] = $data;
        }

        $this->response->setStatusCode(200);
        return $result;
    }

    private function getRealDemographics(string $electionId): array
    {
        $db = $this->getDI()->get('db');
        $voters = $db->fetchAll(
            'SELECT a."angkatan", a."jenisKelamin" FROM "VoteRecord" vr'
            . ' JOIN "Alumni" a ON a."id" = vr."alumniId"'
            . ' WHERE vr."deletedAt" IS NULL AND vr."electionId" = :eid',
            \Phalcon\Db\Enum::FETCH_ASSOC,
            ['eid' => $electionId]
        );

        $angkatanCounts = [];
        $genderCounts = ['Laki-laki' => 0, 'Perempuan' => 0];

        foreach ($voters as $a) {
            $angk = !empty($a['angkatan']) ? (string)$a['angkatan'] : 'Tidak Diketahui';
            if (!isset($angkatanCounts[$angk])) {
                $angkatanCounts[$angk] = 0;
            }
            $angkatanCounts[$angk]++;

            $jk = trim((string)($a['jenisKelamin'] ?? ''));
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
            $angkatanList[] = ['angkatan' => (string)$k, 'count' => (int)$v];
        }

        $totalVoter = count($voters);
        $genderList = [];
        foreach ($genderCounts as $k => $v) {
            if ($v === 0) continue;
            $genderList[] = [
                'gender' => $k,
                'count' => (int)$v,
                'persentase' => $totalVoter > 0 ? round(($v / $totalVoter) * 100, 2) : 0
            ];
        }

        return [
            'angkatan' => $angkatanList,
            'gender' => $genderList
        ];
    }

    public function show($id)
    {
        $election = Election::findFirst([
            'conditions' => 'deletedAt IS NULL AND id = ?0',
            'bind' => [$id]
        ]);

        if (!$election) {
            $this->response->setStatusCode(404);
            return ['error' => 'Pemilu tidak ditemukan'];
        }

        $totalAlumniTerdaftar = (int)Alumni::count([
            'conditions' => "deletedAt IS NULL AND status IN ('ACTIVE', 'APPROVED')"
        ]);

        $candidates = Candidate::find([
            'conditions' => 'deletedAt IS NULL AND electionId = ?0',
            'bind' => [$election->id],
            'order' => 'nomorUrut ASC'
        ]);

        $cList = [];
        $totalSuara = 0;
        foreach ($candidates as $c) {
            $cList[] = $this->formatCandidate($c->toArray());
            $totalSuara += $c->voteCount;
        }

        $data = $election->toArray();
        $data['candidates'] = $cList;
        $data['totalSuara'] = $totalSuara;
        $data['totalAlumniTerdaftar'] = $totalAlumniTerdaftar;
        $data['demographics'] = $this->getRealDemographics($election->id);

        $this->response->setStatusCode(200);
        return $data;
    }

    public function summary($id)
    {
        $election = Election::findFirst([
            'conditions' => 'deletedAt IS NULL AND id = ?0',
            'bind' => [$id]
        ]);

        if (!$election) {
            $this->response->setStatusCode(404);
            return ['error' => 'Pemilu tidak ditemukan'];
        }

        $candidates = Candidate::find([
            'conditions' => 'deletedAt IS NULL AND electionId = ?0',
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

        $totalAlumniTerdaftar = (int)Alumni::count([
            'conditions' => "deletedAt IS NULL AND status IN ('ACTIVE', 'APPROVED')"
        ]);

        $demo = $this->getRealDemographics($election->id);

        return [
            'electionId' => $election->id,
            'judul' => $election->judul,
            'totalSuara' => $totalSuara,
            'totalAlumniTerdaftar' => $totalAlumniTerdaftar,
            'kandidat' => $resultKandidat,
            'demographics' => $demo
        ];
    }

    public function vote()
    {
        Election::checkAndCompleteExpiredElections();
        // Get alumni ID from JWT token via DI container
        try {
            $alumniId = $this->getDI()->get('userId');
        } catch (\Exception $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

            $alumniId = null;
        }

        if (!$alumniId) {
            $this->response->setStatusCode(401);
            return ['error' => 'Unauthorized: Identitas pemilih tidak ditemukan.'];
        }

        $alumni = Alumni::findFirst([
            'conditions' => 'deletedAt IS NULL AND id = ?0',
            'bind' => [$alumniId]
        ]);

        if (!$alumni || !in_array($alumni->status, ['APPROVED', 'ACTIVE'])) {
            $this->response->setStatusCode(403);
            return ['error' => 'Hanya alumni terverifikasi yang dapat melakukan voting.'];
        }

        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        $candidateId = $request['candidateId'] ?? null;

        if (!$candidateId) {
            $this->response->setStatusCode(400);
            return ['error' => 'Pilih kandidat terlebih dahulu.'];
        }

        $candidate = Candidate::findFirst([
            'conditions' => 'deletedAt IS NULL AND id = ?0',
            'bind' => [$candidateId]
        ]);

        if (!$candidate) {
            $this->response->setStatusCode(404);
            return ['error' => 'Kandidat tidak ditemukan.'];
        }

        $election = Election::findFirst([
            'conditions' => 'deletedAt IS NULL AND id = ?0',
            'bind' => [$candidate->electionId]
        ]);

        $elStatus = $election ? strtolower(trim($election->status)) : '';
        if (!$election || !in_array($elStatus, ['active', 'ongoing'])) {
            $this->response->setStatusCode(400);
            return ['error' => 'Pemilu ini sedang tidak aktif (atau sudah selesai)'];
        }
        if ($election->periodeEnd && strtotime($election->periodeEnd) <= time()) {
            $this->response->setStatusCode(400);
            return ['error' => 'Waktu pemungutan suara telah berakhir.'];
        }

        // Check if the user has already voted in this election
        $existingVote = VoteRecord::findFirst([
            'conditions' => 'deletedAt IS NULL AND alumniId = ?0 AND electionId = ?1',
            'bind' => [$alumniId, $election->id]
        ]);

        if ($existingVote) {
            $this->response->setStatusCode(400);
            return ['error' => 'Anda sudah memberikan suara pada pemilu ini.'];
        }

        $db = $this->getDI()->get('db');
        $db->begin();

        $voteRecord = new VoteRecord();
        $voteRecord->alumniId = $alumniId;
        $voteRecord->electionId = $election->id;
        $voteRecord->candidateId = $candidate->id;

        if ($voteRecord->save() === false) {
            $db->rollback();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal merekam suara Anda.'];
        }

        $candidate->voteCount += 1;
        if ($candidate->save() === false) {
            $db->rollback();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal memperbarui total suara kandidat.'];
        }

        $db->commit();

        $this->di->getShared('auditLog')->log([
            'source'      => 'portal',
            'action'      => 'create',
            'actor'       => ['id' => $alumni->id, 'type' => 'alumni', 'name' => $alumni->nama, 'role' => 'Alumni'],
            'entityType'  => 'Election',
            'entityId'    => $election->id,
            'description' => "Alumni {$alumni->nama} memberikan suara pada pemilu {$election->judul}",
        ]);

        $this->response->setStatusCode(200);
        return ['message' => 'Vote berhasil ditambahkan'];
    }
}
