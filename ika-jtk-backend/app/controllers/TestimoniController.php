<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Testimoni;
use App\Models\Alumni;

class TestimoniController extends Controller
{
    /**
     * GET /api/testimoni
     * Public list of approved, public testimonials.
     */
    public function index()
    {
        $list = Testimoni::find([
            'conditions' => 'deletedAt IS NULL AND LOWER(status) = ?0 AND LOWER(visibility) = ?1',
            'bind'       => ['published', 'public'],
        ]);

        $arr = [];
        foreach ($list as $item) {
            $itemArr = $item->toArray();
            $alumni = $item->getRelated('Alumni');
            if ($alumni) {
                $itemArr['alumniNama'] = $alumni->nama;
                $itemArr['alumniAngkatan'] = $alumni->angkatan;
                $itemArr['alumniAvatarUrl'] = $alumni->avatarUrl;
            }
            $arr[] = $itemArr;
        }

        shuffle($arr);
        $result = array_slice($arr, 0, 5);

        $this->response->setStatusCode(200);
        return $result;
    }

    /**
     * GET /api/testimoni/me
     * Returns the latest testimonial submitted by the logged-in alumni.
     */
    public function me()
    {
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
            return ['error' => 'Unauthorized'];
        }

        $latest = Testimoni::findFirst([
            'conditions' => 'deletedAt IS NULL AND alumniId = ?0',
            'bind'       => [$alumniId],
            'order'      => 'createdAt DESC',
        ]);

        if (!$latest) {
            $this->response->setStatusCode(200);
            return ['data' => null];
        }

        $rejectCount = Testimoni::count([
            'conditions' => 'alumniId = ?0 AND status = ?1 AND deletedAt IS NULL',
            'bind'       => [$alumniId, 'Rejected']
        ]);

        $this->response->setStatusCode(200);
        return [
            'data' => [
                'id'        => $latest->id,
                'isi'       => $latest->isi,
                'status'       => $latest->status,
                'createdAt'    => $latest->createdAt,
                'rejectReason' => $latest->rejectReason,
                'rejectCount'  => $rejectCount,
            ],
        ];
    }

    /**
     * POST /api/testimoni
     * Submit a testimonial as the logged-in alumni. Nama/Angkatan/Avatar are
     * taken from the authenticated Alumni record, never from the request body.
     */
    public function create()
    {
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
            return ['error' => 'Unauthorized: Identitas pengirim tidak ditemukan.'];
        }

        $alumni = Alumni::findFirst([
            'conditions' => 'deletedAt IS NULL AND id = ?0',
            'bind'       => [$alumniId],
        ]);

        if (!$alumni || !in_array($alumni->status, ['APPROVED', 'ACTIVE'])) {
            $this->response->setStatusCode(403);
            return ['error' => 'Hanya alumni terverifikasi yang dapat mengirim testimoni.'];
        }

        // Cek apakah sudah ada testimoni (Pending, Published, atau Rejected)
        $latest = Testimoni::findFirst([
            'conditions' => 'deletedAt IS NULL AND alumniId = ?0',
            'bind'       => [$alumniId],
            'order'      => 'createdAt DESC',
        ]);

        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $isi = isset($req['isi']) ? trim($req['isi']) : '';
        if ($isi === '') {
            $this->response->setStatusCode(400);
            return ['error' => 'Semua field wajib diisi.'];
        }

        $visibility = $req['visibility'] ?? 'public';
        if (!in_array($visibility, ['public', 'private'])) {
            $visibility = 'public';
        }

        if ($latest) {
            $latestStatus = strtolower(trim($latest->status));
            if ($latestStatus === 'pending') {
                $this->response->setStatusCode(400);
                return ['error' => 'Anda sudah memiliki testimoni yang sedang dalam proses review. Silakan tunggu hingga proses selesai.'];
            }
            if ($latestStatus === 'published') {
                $this->response->setStatusCode(400);
                return ['error' => 'Testimoni Anda sudah disetujui. Anda tidak dapat mengajukan testimoni baru.'];
            }
        }

        // Buat record baru untuk menyimpan riwayat testimoni 1, 2, 3
        $item = new Testimoni();
        $item->alumniId        = $alumni->id;
        $item->alumniNama      = $alumni->nama;
        $item->alumniAngkatan  = $alumni->angkatan;
        $item->alumniAvatarUrl = $alumni->avatarUrl;
        $item->isi             = $isi;
        $item->visibility      = $visibility;
        $item->status          = 'Pending';
        $item->rejectCount     = null;

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal mengirim testimoni: ' . implode(', ', $item->getMessages())];
        }

        $this->di->getShared('auditLog')->log([
            'source'      => 'portal',
            'action'      => 'create',
            'actor'       => ['id' => $alumni->id, 'type' => 'alumni', 'name' => $alumni->nama, 'role' => 'Alumni'],
            'entityType'  => 'Testimoni',
            'entityId'    => $item->id,
            'description' => "Alumni {$alumni->nama} mengirim pengajuan testimoni",
        ]);

        $this->response->setStatusCode(201);
        return $item->toArray();
    }
}
