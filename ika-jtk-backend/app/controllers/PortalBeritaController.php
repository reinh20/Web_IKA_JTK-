<?php
namespace App\Controllers;
use Phalcon\Mvc\Controller;
use App\Models\Berita;
use App\Traits\AuthorFormatter;

class PortalBeritaController extends Controller
{
    use AuthorFormatter;
    public function index()
    {
        $kategori = $this->request->getQuery('kategori');
        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = $this->request->getQuery('search', 'string', '');

        $conditions = '[deletedAt] IS NULL AND status = :status:';
        $bind = ['status' => 'Published'];

        if (is_string($kategori) && $kategori !== '' && $kategori !== 'Semua') {
            $conditions .= ' AND LOWER(kategori) = LOWER(:kategori:)';
            $bind['kategori'] = $kategori;
        }

        if ($search !== '') {
            $conditions .= ' AND (LOWER(judul) LIKE LOWER(:search_start:) OR LOWER(judul) LIKE LOWER(:search_space:) OR LOWER(konten) LIKE LOWER(:search_any:))';
            $bind['search_start'] = $search . '%';
            $bind['search_space'] = '% ' . $search . '%';
            $bind['search_any'] = '%' . $search . '%';
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => '[publishedAt] DESC, [createdAt] DESC, [id] DESC'
        ];

        if ($page !== null) {
            $total = Berita::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $list = Berita::find($queryOpts);
            $result = [];
            foreach ($list as $item) {
                $result[] = $this->formatBerita($item);
            }

            $this->response->setStatusCode(200);
            return [
                'data' => $result,
                'total' => $total,
            ];
        }

        // Fallback
        $list = Berita::find($queryOpts);
        $result = [];
        foreach ($list as $item) {
            $result[] = $this->formatBerita($item);
        }
        $this->response->setStatusCode(200);
        return $result;
    }

    public function show($id)
    {
        $item = Berita::findFirst([
            'conditions' => 'id = ?0 AND status = ?1',
            'bind' => [$id, 'Published']
        ]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Berita tidak ditemukan.'];
        }
        $this->response->setStatusCode(200);
        return $this->formatBerita($item);
    }

    private function formatBerita($item)
    {
        $data = $item->toArray();
        $data['author'] = $this->formatAuthor($data);
        unset($data['authorId'], $data['authorNama'], $data['authorRole'], $data['authorAvatarUrl']);

        $data['highlightedAlumni'] = null;
        $highlightedId = $data['highlightedAlumniId'] ?? null;
        if (!empty($highlightedId)) {
            $alumni = \App\Models\Alumni::findFirst([
                'conditions' => 'id = ?0 AND deletedAt IS NULL',
                'bind' => [$highlightedId]
            ]);
            if ($alumni) {
                $data['highlightedAlumni'] = [
                    'id' => $alumni->id,
                    'nama' => $alumni->nama,
                    'angkatan' => $alumni->angkatan,
                    'avatarUrl' => $alumni->avatarUrl ?? '',
                ];
            }
        }

        return $data;
    }

    public function create()
    {
        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        if (!$this->getDI()->has('userId') || !$this->getDI()->get('userId')) {
            $this->response->setStatusCode(401);
            return ['error' => 'Unauthorized'];
        }
        $userId = $this->getDI()->get('userId');

        $item = new Berita();
        $item->judul = $req['judul'] ?? '';
        $item->konten = $req['konten'] ?? '';
        $item->bannerUrl = $req['bannerUrl'] ?? null;
        $item->bannerThumbnailUrl = $req['bannerThumbnailUrl'] ?? null;
        $item->kategori = $req['kategori'] ?? 'Pengumuman';
        $item->tags = $req['tags'] ?? '';
        $item->status = 'Submission';
        $item->authorId = $userId;
        
        $alumni = \App\Models\Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$userId]]);
        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['error' => 'Alumni tidak ditemukan'];
        }
        if (!in_array($alumni->status, ['APPROVED', 'ACTIVE'])) {
            $this->response->setStatusCode(403);
            return ['error' => 'Hanya alumni yang sudah disetujui oleh admin (Approved) yang dapat mengupload konten.'];
        }

        $item->authorNama = $alumni->nama;
        $item->authorRole = 'Alumni';
        $item->authorAvatarUrl = $alumni->avatarUrl;

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menyimpan berita: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(201);
        return ['message' => 'Berita berhasil disubmit.', 'data' => $item->toArray()];
    }
}
