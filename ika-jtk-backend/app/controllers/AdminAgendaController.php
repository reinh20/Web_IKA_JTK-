<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Agenda;
use App\Traits\AuthorFormatter;

class AdminAgendaController extends Controller
{
    use AuthorFormatter;
    public function index()
    {
        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = $this->request->getQuery('search', 'string', '');
        $status = $this->request->getQuery('status', 'string', '');
        $tab = $this->request->getQuery('tab', 'string', '');

        $conditions = '[deletedAt] IS NULL';
        $bind = [];

        if ($tab === 'submission') {
            $conditions .= ' AND status = :status_submission:';
            $bind['status_submission'] = 'Submission';
        } else if ($tab === 'semua' || $tab !== '') {
            $conditions .= ' AND status != :status_submission:';
            $bind['status_submission'] = 'Submission';
        }
        
        if ($status !== '' && $status !== 'all' && $tab !== 'submission') {
            $conditions .= ' AND status = :status:';
            $bind['status'] = $status;
        }

        if ($search !== '') {
            $conditions .= ' AND (LOWER(judul) LIKE LOWER(:search:) OR LOWER(tags) LIKE LOWER(:search:))';
            $bind['search'] = '%' . $search . '%';
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => '[createdAt] DESC, [id] DESC'
        ];

        if ($page !== null) {
            $total = Agenda::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $semuaCount = Agenda::count([
                'conditions' => '[deletedAt] IS NULL AND status != :status_submission:',
                'bind' => ['status_submission' => 'Submission']
            ]);

            $submissionCount = Agenda::count([
                'conditions' => '[deletedAt] IS NULL AND status = :status_submission:',
                'bind' => ['status_submission' => 'Submission']
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $list = Agenda::find($queryOpts);
            $result = [];
            foreach ($list as $item) {
                $data = $this->format($item);
                if (is_string($data['author'])) $data['author'] = json_decode($data['author'], true);
                $result[] = $data;
            }

            $this->response->setStatusCode(200);
            return [
                'data' => $result,
                'total' => $total,
                'semuaCount' => $semuaCount,
                'submissionCount' => $submissionCount
            ];
        }

        // Fallback for non-paginated queries
        $list = Agenda::find($queryOpts);
        $result = [];
        foreach ($list as $item) {
            $data = $this->format($item);
            if (is_string($data['author'])) $data['author'] = json_decode($data['author'], true);
            $result[] = $data;
        }
        $this->response->setStatusCode(200);
        return $result;
    }

    public function show($id)
    {
        $item = Agenda::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Agenda not found'];
        }
        $data = $this->format($item);
        if (is_string($data['author'])) $data['author'] = json_decode($data['author'], true);
        $this->response->setStatusCode(200);
        return $data;
    }

    public function create()
    {
        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $item = new Agenda();
        $item->noEvent = $req['noEvent'] ?? '';
        $item->judul = $req['judul'] ?? '';
        $item->deskripsi = $req['deskripsi'] ?? '';
        $item->bannerUrl = $req['bannerUrl'] ?? null;
        $item->bannerThumbnailUrl = $req['bannerThumbnailUrl'] ?? null;
        $item->tags = $req['tags'] ?? '';
        $item->tanggalEvent = $req['tanggalEvent'] ?? date('Y-m-d');
        $item->waktu = $req['waktu'] ?? '';
        $item->lokasi = $req['lokasi'] ?? '';
        $item->status = $req['status'] ?? 'Draft';

        if (isset($req['author']) && is_array($req['author'])) {
            $item->authorId = $req['author']['id'] ?? '';
            $item->authorNama = $req['author']['nama'] ?? '';
            $item->authorRole = $req['author']['role'] ?? '';
            $item->authorAvatarUrl = $req['author']['avatarUrl'] ?? '';
        }
        if (empty($item->authorId) && $this->getDI()->has('userId')) {
            $item->authorId = $this->getDI()->get('userId') ?: '8fb57aec0d5becbad9460ce4c5d32811';
        }

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menyimpan agenda: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(201);
        return $this->format($item);
    }

    public function update($id)
    {
        $item = Agenda::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Agenda not found'];
        }

        $prevStatus = $item->status;
        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        if (isset($req['noEvent'])) $item->noEvent = $req['noEvent'];
        if (isset($req['judul'])) $item->judul = $req['judul'];
        if (isset($req['deskripsi'])) $item->deskripsi = $req['deskripsi'];
        if (array_key_exists('bannerUrl', $req)) $item->bannerUrl = $req['bannerUrl'];
        if (array_key_exists('bannerThumbnailUrl', $req)) $item->bannerThumbnailUrl = $req['bannerThumbnailUrl'];
        if (isset($req['tags'])) $item->tags = $req['tags'];
        if (isset($req['tanggalEvent'])) $item->tanggalEvent = $req['tanggalEvent'];
        if (isset($req['waktu'])) $item->waktu = $req['waktu'];
        if (isset($req['lokasi'])) $item->lokasi = $req['lokasi'];
        if (isset($req['status'])) $item->status = $req['status'];

        if (isset($req['author']) && is_array($req['author'])) {
            $item->authorId = $req['author']['id'] ?? '';
            $item->authorNama = $req['author']['nama'] ?? '';
            $item->authorRole = $req['author']['role'] ?? '';
            $item->authorAvatarUrl = $req['author']['avatarUrl'] ?? '';
        }

        // Custom rule: if edited by admin and previous status was Submission, it becomes Draft
        if ($item->status === 'Submission') {
            $item->status = 'Draft';
        }

        if ($item->status === 'Published') {
            if ($prevStatus !== 'Published' || empty($item->publishedAt)) {
                $item->publishedAt = date('Y-m-d H:i:s');
            }
        } else {
            $item->publishedAt = null;
        }

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal memperbarui agenda: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $this->format($item);
    }

    public function delete($id)
    {
        $item = Agenda::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Agenda not found'];
        }
        $item->deletedAt = date('Y-m-d H:i:s');
        if ($item->save() === false) {
            $messages = $item->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus.', 'detail' => implode(', ', $messages)];
        }
        $this->response->setStatusCode(200);
        return ['message' => 'Agenda berhasil dihapus'];
    }

    public function approve($id)
    {
        $item = Agenda::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Agenda not found'];
        }

        $item->status = 'Published';
        $item->publishedAt = date('Y-m-d H:i:s');

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menyetujui agenda: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $this->format($item);
    }

    public function reject($id)
    {
        $item = Agenda::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Agenda not found'];
        }

        $item->status = 'Rejected';
        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menolak agenda: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $this->format($item);
    }

    private function format($item)
    {
        $data = $item->toArray();
        $data['author'] = $this->formatAuthor($data);
        unset($data['authorId'], $data['authorNama'], $data['authorRole'], $data['authorAvatarUrl']);

        $peserta = \App\Models\PesertaAgenda::find([
            'conditions' => '[agendaId] = ?0',
            'bind' => [$item->id],
            'order' => '[createdAt] ASC'
        ]);
        
        $data['peserta'] = [];
        foreach ($peserta as $p) {
            $alumni = \App\Models\Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$p->alumniId]]);
            $data['peserta'][] = [
                'id' => $p->alumniId,
                'nama' => $p->nama,
                'email' => $p->email,
                'angkatan' => $alumni ? $alumni->angkatan : '',
                'avatarUrl' => $alumni ? $alumni->avatarUrl : '',
                'joinedAt' => $p->createdAt,
                'waktuReservasi' => $p->createdAt
            ];
        }

        return $data;
    }
}
