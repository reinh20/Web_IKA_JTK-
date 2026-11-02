<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Testimoni;

class AdminTestimoniController extends Controller
{
    public function index()
    {
        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = $this->request->getQuery('search', 'string', '');
        $status = $this->request->getQuery('status', 'string', '');
        $tab = $this->request->getQuery('tab', 'string', '');

        $conditions = 'deletedAt IS NULL';
        $bind = [];

        $targetStatus = '';
        if ($status !== '' && strtolower($status) !== 'all') {
            $targetStatus = $status;
        } else if ($tab !== '' && strtolower($tab) !== 'semua') {
            $targetStatus = $tab;
        }

        if ($targetStatus !== '') {
            $conditions .= ' AND LOWER(status) = LOWER(:targetStatus:)';
            $bind['targetStatus'] = $targetStatus;
        }

        if ($search !== '') {
            $conditions .= ' AND (LOWER(alumniNama) LIKE LOWER(:search_start:) OR LOWER(alumniNama) LIKE LOWER(:search_space:) OR LOWER(isi) LIKE LOWER(:search_any:))';
            $bind['search_start'] = $search . '%';
            $bind['search_space'] = '% ' . $search . '%';
            $bind['search_any'] = '%' . $search . '%';
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => 'createdAt DESC'
        ];

        if ($page !== null) {
            $total = Testimoni::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $semuaCount = Testimoni::count([
                'conditions' => 'deletedAt IS NULL'
            ]);

            $submissionCount = Testimoni::count([
                'conditions' => 'deletedAt IS NULL AND LOWER(status) = :status_pending:',
                'bind' => ['status_pending' => 'pending']
            ]);

            $publishedCount = Testimoni::count([
                'conditions' => 'deletedAt IS NULL AND LOWER(status) = :status_published:',
                'bind' => ['status_published' => 'published']
            ]);

            $rejectedCount = Testimoni::count([
                'conditions' => 'deletedAt IS NULL AND LOWER(status) = :status_rejected:',
                'bind' => ['status_rejected' => 'rejected']
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $list = Testimoni::find($queryOpts);
            $listArray = [];
            foreach ($list as $item) {
                $arr = $item->toArray();
                $alumni = $item->getRelated('Alumni');
                if ($alumni) {
                    $arr['alumniNama'] = $alumni->nama;
                    $arr['alumniAngkatan'] = $alumni->angkatan;
                    $arr['alumniAvatarUrl'] = $alumni->avatarUrl;
                }
                $arr['rejectCount'] = Testimoni::count([
                    'conditions' => 'alumniId = ?0 AND status = ?1 AND deletedAt IS NULL',
                    'bind' => [$arr['alumniId'], 'Rejected']
                ]);
                $listArray[] = $arr;
            }

            $this->response->setStatusCode(200);
            return [
                'data' => $listArray,
                'total' => $total,
                'semuaCount' => $semuaCount,
                'submissionCount' => $submissionCount,
                'publishedCount' => $publishedCount,
                'rejectedCount' => $rejectedCount
            ];
        }

        $list = Testimoni::find($queryOpts);
        $listArray = [];
        foreach ($list as $item) {
            $arr = $item->toArray();
            $alumni = $item->getRelated('Alumni');
            if ($alumni) {
                $arr['alumniNama'] = $alumni->nama;
                $arr['alumniAngkatan'] = $alumni->angkatan;
                $arr['alumniAvatarUrl'] = $alumni->avatarUrl;
            }
            $arr['rejectCount'] = Testimoni::count([
                'conditions' => 'alumniId = ?0 AND status = ?1 AND deletedAt IS NULL',
                'bind' => [$arr['alumniId'], 'Rejected']
            ]);
            $listArray[] = $arr;
        }

        $this->response->setStatusCode(200);
        return $listArray;
    }

    public function show($id)
    {
        $item = Testimoni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Testimoni not found'];
        }
        $itemArray = $item->toArray();
        $alumni = $item->getRelated('Alumni');
        if ($alumni) {
            $itemArray['alumniNama'] = $alumni->nama;
            $itemArray['alumniAngkatan'] = $alumni->angkatan;
            $itemArray['alumniAvatarUrl'] = $alumni->avatarUrl;
        }

        $itemArray['rejectCount'] = Testimoni::count([
            'conditions' => 'alumniId = ?0 AND status = ?1 AND deletedAt IS NULL',
            'bind' => [$itemArray['alumniId'], 'Rejected']
        ]);

        $this->response->setStatusCode(200);
        return $itemArray;
    }

    public function update($id)
    {
        $item = Testimoni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Testimoni not found'];
        }

        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        if (isset($req['status'])) {
            if ($req['status'] === 'Rejected') {
                // Increment penolakan secara dinamis berdasarkan riwayat
                $previousRejectedCount = Testimoni::count([
                    'conditions' => 'alumniId = ?0 AND status = ?1 AND deletedAt IS NULL AND id != ?2',
                    'bind' => [$item->alumniId, 'Rejected', $item->id]
                ]);
                $newCount = $previousRejectedCount + 1;
                $item->rejectCount = $newCount;

                if ($newCount > 3) {
                    // Penolakan ke-4 → hapus (soft-delete)
                    $item->deletedAt = date('Y-m-d H:i:s');
                    if ($item->save() === false) {
                        $this->response->setStatusCode(500);
                        return ['error' => 'Gagal menghapus testimoni pada penolakan ke-4.'];
                    }
                    $this->response->setStatusCode(200);
                    return ['message' => 'deleted', 'rejectCount' => $newCount];
                }

                // Masih < 3: set status Rejected
                $item->status = 'Rejected';
                if (isset($req['rejectReason'])) {
                    $item->rejectReason = $req['rejectReason'];
                }
            } else {
                $item->status = $req['status'];
                if ($req['status'] === 'Published' || $req['status'] === 'Pending') {
                    $item->rejectReason = null; // Clear reason if published or reset
                }
            }
        }
        if (isset($req['visibility'])) $item->visibility = $req['visibility'];
        if (isset($req['isi'])) $item->isi = $req['isi'];

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal memperbarui testimoni: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $item->toArray();
    }

    public function delete($id)
    {
        $item = Testimoni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Testimoni not found'];
        }
        $item->deletedAt = date('Y-m-d H:i:s');
        if ($item->save() === false) {
            $messages = $item->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus.', 'detail' => implode(', ', $messages)];
        }
        $this->response->setStatusCode(200);
        return ['message' => 'Testimoni berhasil dihapus'];
    }
}
