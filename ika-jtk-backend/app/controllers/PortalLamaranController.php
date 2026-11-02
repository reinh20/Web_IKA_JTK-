<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Lamaran;

class PortalLamaranController extends Controller
{
    public function index()
    {
        if (!$this->getDI()->has('userId') || !$this->getDI()->get('userId')) {
            $this->response->setStatusCode(401);
            return ['error' => 'Unauthorized'];
        }
        $userId = $this->getDI()->get('userId');

        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);

        $conditions = 'alumniId = ?0 AND [deletedAt] IS NULL';
        $bind = [$userId];

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => '[createdAt] DESC'
        ];

        if ($page !== null) {
            $total = Lamaran::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $lamaranList = Lamaran::find($queryOpts);
            $data = [];
            foreach ($lamaranList as $lamaran) {
                $loker = $lamaran->loker;
                $data[] = [
                    'id' => $lamaran->id,
                    'lokerId' => $lamaran->lokerId,
                    'posisi' => $loker ? $loker->posisi : 'Loker dihapus',
                    'perusahaan' => $loker ? $loker->namaPerusahaan : '-',
                    'logoUrl' => $loker ? $loker->logoUrl : '',
                    'status' => $lamaran->status,
                    'dilamarPada' => date('d M Y', strtotime($lamaran->createdAt))
                ];
            }

            $this->response->setStatusCode(200);
            return [
                'data' => $data,
                'total' => $total,
            ];
        }

        // Fallback
        $lamaranList = Lamaran::find($queryOpts);

        $data = [];
        foreach ($lamaranList as $lamaran) {
            $loker = $lamaran->loker;
            $data[] = [
                'id' => $lamaran->id,
                'lokerId' => $lamaran->lokerId,
                'posisi' => $loker ? $loker->posisi : 'Loker dihapus',
                'perusahaan' => $loker ? $loker->namaPerusahaan : '-',
                'logoUrl' => $loker ? $loker->logoUrl : '',
                'status' => $lamaran->status,
                'dilamarPada' => date('d M Y', strtotime($lamaran->createdAt))
            ];
        }

        $this->response->setStatusCode(200);
        return $data;
    }
}
