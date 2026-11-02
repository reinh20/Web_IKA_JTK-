<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Election;
use App\Models\Candidate;
use App\Traits\CandidateFormatter;

class AdminPemiluController extends Controller
{
    use CandidateFormatter;
    public function index()
    {
        Election::checkAndCompleteExpiredElections();

        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = $this->request->getQuery('search', 'string', '');
        $status = $this->request->getQuery('status', 'string', '');

        $conditions = 'deletedAt IS NULL';
        $bind = [];

        if ($status !== '' && $status !== 'all') {
            $conditions .= ' AND status = :status:';
            $bind['status'] = $status;
        }

        if ($search !== '') {
            $conditions .= ' AND (LOWER(title) LIKE LOWER(:search:))';
            $bind['search'] = '%' . $search . '%';
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => 'createdAt DESC'
        ];

        if ($page !== null) {
            $total = Election::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $elections = Election::find($queryOpts);
            $result = [];
            foreach ($elections as $e) {
                $eData = $e->toArray();
                
                // Get candidates
                $candidates = Candidate::find([
                    'conditions' => 'electionId = ?0 AND deletedAt IS NULL',
                    'bind' => [$e->id]
                ]);
                
                $eData['kandidat'] = [];
                foreach ($candidates as $c) {
                    $eData['kandidat'][] = $this->formatCandidate($c->toArray());
                }
                
                $result[] = $eData;
            }

            $this->response->setStatusCode(200);
            return [
                'data' => $result,
                'total' => $total,
            ];
        }

        // Fallback for non-paginated requests
        $elections = Election::find($queryOpts);
        $result = [];
        foreach ($elections as $e) {
            $eData = $e->toArray();
            
            // Get candidates
            $candidates = Candidate::find([
                'conditions' => 'electionId = ?0 AND deletedAt IS NULL',
                'bind' => [$e->id]
            ]);
            
            $eData['kandidat'] = [];
            foreach ($candidates as $c) {
                $eData['kandidat'][] = $this->formatCandidate($c->toArray());
            }
            
            $result[] = $eData;
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
            return ['error' => 'Pemilu not found'];
        }

        $candidates = Candidate::find([
            'conditions' => 'electionId = ?0 AND deletedAt IS NULL',
            'bind' => [$election->id]
        ]);

        $eData = $election->toArray();
        $eData['kandidat'] = [];
        foreach ($candidates as $c) {
            $eData['kandidat'][] = $this->formatCandidate($c->toArray());
        }

        $this->response->setStatusCode(200);
        return $eData;
    }

    public function create()
    {
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        
        $election = new Election();
        $election->assign($request, [
            'judul', 'deskripsi', 'periodeStart', 'periodeEnd', 'kandidatStart', 'kandidatEnd', 'pengumumanDate', 'pelantikanDate', 'status', 'totalVoter', 'totalSuara'
        ]);

        if ($election->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal membuat pemilu', 'messages' => $election->getMessages()];
        }

        $this->response->setStatusCode(201);
        return ['message' => 'Pemilu berhasil dibuat', 'data' => $election->toArray()];
    }

    public function update($id)
    {
        $election = Election::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$election) {
            $this->response->setStatusCode(404);
            return ['error' => 'Pemilu not found'];
        }

        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPut();
        $election->assign($request, [
            'judul', 'deskripsi', 'periodeStart', 'periodeEnd', 'kandidatStart', 'kandidatEnd', 'pengumumanDate', 'pelantikanDate', 'status', 'totalVoter', 'totalSuara'
        ]);

        if ($election->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal mengupdate pemilu', 'messages' => $election->getMessages()];
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Pemilu berhasil diupdate', 'data' => $election->toArray()];
    }

    public function delete($id)
    {
        $election = Election::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$election) {
            $this->response->setStatusCode(404);
            return ['error' => 'Pemilu not found'];
        }

        $election->deletedAt = date('Y-m-d H:i:s');
        if ($election->save() === false) {
            $messages = $election->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus.', 'detail' => implode(', ', $messages)];
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Pemilu berhasil dihapus'];
    }
}
