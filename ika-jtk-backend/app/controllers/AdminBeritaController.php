<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Berita;
use App\Traits\AuthorFormatter;

class AdminBeritaController extends Controller
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
            $conditions .= ' AND (LOWER(judul) LIKE LOWER(:search_start:) OR LOWER(judul) LIKE LOWER(:search_space:) OR LOWER(tags) LIKE LOWER(:search_any:))';
            $bind['search_start'] = $search . '%';
            $bind['search_space'] = '% ' . $search . '%';
            $bind['search_any'] = '%' . $search . '%';
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => '[createdAt] DESC, [id] DESC'
        ];

        if ($page !== null) {
            $total = Berita::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $semuaCount = Berita::count([
                'conditions' => '[deletedAt] IS NULL AND status != :status_submission:',
                'bind' => ['status_submission' => 'Submission']
            ]);

            $submissionCount = Berita::count([
                'conditions' => '[deletedAt] IS NULL AND status = :status_submission:',
                'bind' => ['status_submission' => 'Submission']
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $list = Berita::find($queryOpts);
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
        $list = Berita::find($queryOpts);
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
        $item = Berita::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Berita not found'];
        }
        $data = $this->format($item);
        if (is_string($data['author'])) $data['author'] = json_decode($data['author'], true);
        $this->response->setStatusCode(200);
        return $data;
    }

    public function create()
    {
        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $item = new Berita();
        $item->noBerita = $req['noBerita'] ?? '';
        $item->judul = $req['judul'] ?? '';
        $item->konten = $req['konten'] ?? '';
        $item->bannerUrl = $req['bannerUrl'] ?? null;
        $item->bannerThumbnailUrl = $req['bannerThumbnailUrl'] ?? null;
        $item->kategori = $req['kategori'] ?? 'Pengumuman';
        $item->tags = $req['tags'] ?? '';
        $item->status = $req['status'] ?? 'Draft';
        $item->highlightedAlumniId = !empty($req['highlightedAlumniId']) ? $req['highlightedAlumniId'] : null;

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
            return ['error' => 'Gagal menyimpan berita: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(201);
        return $this->format($item);
    }

    public function update($id)
    {
        $item = Berita::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Berita not found'];
        }

        $prevStatus = $item->status;
        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        if (isset($req['noBerita'])) $item->noBerita = $req['noBerita'];
        if (isset($req['judul'])) $item->judul = $req['judul'];
        if (isset($req['konten'])) $item->konten = $req['konten'];
        if (array_key_exists('bannerUrl', $req)) $item->bannerUrl = $req['bannerUrl'];
        if (array_key_exists('bannerThumbnailUrl', $req)) $item->bannerThumbnailUrl = $req['bannerThumbnailUrl'];
        if (isset($req['kategori'])) $item->kategori = $req['kategori'];
        if (isset($req['tags'])) $item->tags = $req['tags'];
        if (isset($req['status'])) $item->status = $req['status'];
        if (array_key_exists('highlightedAlumniId', $req)) {
            $item->highlightedAlumniId = !empty($req['highlightedAlumniId']) ? $req['highlightedAlumniId'] : null;
        }

        if (isset($req['author']) && is_array($req['author'])) {
            $item->authorId = $req['author']['id'] ?? '';
            $item->authorNama = $req['author']['nama'] ?? '';
            $item->authorRole = $req['author']['role'] ?? '';
            $item->authorAvatarUrl = $req['author']['avatarUrl'] ?? '';
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
            return ['error' => 'Gagal memperbarui berita: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $this->format($item);
    }

    public function approve($id)
    {
        $item = Berita::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Berita not found'];
        }

        $item->status = 'Published';
        $item->publishedAt = date('Y-m-d H:i:s');

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menyetujui berita: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Berita berhasil disetujui', 'data' => $this->format($item)];
    }

    public function reject($id)
    {
        $item = Berita::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Berita not found'];
        }

        $item->status = 'Rejected';

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menolak berita: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Berita berhasil ditolak', 'data' => $this->format($item)];
    }

    public function delete($id)
    {
        $item = Berita::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Berita not found'];
        }
        $item->deletedAt = date('Y-m-d H:i:s');
        if ($item->save() === false) {
            $messages = $item->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus.', 'detail' => implode(', ', $messages)];
        }
        $this->response->setStatusCode(200);
        return ['message' => 'Berita berhasil dihapus'];
    }

    private function format($item)
    {
        $data = $item->toArray();
        $data['author'] = $this->formatAuthor($data);
        unset($data['authorId'], $data['authorNama'], $data['authorRole'], $data['authorAvatarUrl']);
        $data['highlightedAlumniId'] = $data['highlightedAlumniId'] ?? null;
        return $data;
    }
}
