<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\AuditLog;

class AdminAuditLogController extends Controller
{
    private function format(AuditLog $log): array
    {
        $data = $log->toArray();

        // afterFetch already decodes changes/metadata into arrays; toArray() re-serializes
        // if the model property has an array value, but Phalcon returns arrays as-is.
        // Enforce array output for consistency:
        if (is_string($data['changes']  ?? null))  $data['changes']  = json_decode($data['changes'],  true);
        if (is_string($data['metadata'] ?? null)) $data['metadata'] = json_decode($data['metadata'], true);

        if (!empty($data['createdAt'])) {
            $ts = strtotime($data['createdAt']);
            if ($ts !== false) {
                $data['createdAt'] = gmdate('Y-m-d\TH:i:s\Z', $ts);
            }
        }

        return $data;
    }

    public function index()
    {
        $page       = max(1, (int) ($this->request->getQuery('page') ?: 1));
        $perPage    = min(100, max(1, (int) ($this->request->getQuery('perPage') ?: 20)));
        $action     = trim((string) $this->request->getQuery('action'));
        $actorId    = trim((string) $this->request->getQuery('actorId'));
        $source     = trim((string) $this->request->getQuery('source'));
        $entityType = trim((string) $this->request->getQuery('entityType'));
        $entityId   = trim((string) $this->request->getQuery('entityId'));
        $search     = trim((string) $this->request->getQuery('search'));
        $dateFrom   = trim((string) $this->request->getQuery('dateFrom'));
        $dateTo     = trim((string) $this->request->getQuery('dateTo'));

        $conditions = [];
        $bind = [];
        $i = 0;

        if ($action !== '')     { $conditions[] = "action = ?$i";     $bind[] = $action;     $i++; }
        if ($actorId !== '')    { $conditions[] = "actorId = ?$i";    $bind[] = $actorId;    $i++; }
        if ($source !== '')     { $conditions[] = "source = ?$i";     $bind[] = $source;     $i++; }
        if ($entityType !== '') { $conditions[] = "entityType = ?$i"; $bind[] = $entityType; $i++; }
        if ($entityId !== '')   { $conditions[] = "entityId = ?$i";   $bind[] = $entityId;   $i++; }
        if ($dateFrom !== '')   { $conditions[] = "createdAt >= ?$i"; $bind[] = $dateFrom . ' 00:00:00'; $i++; }
        if ($dateTo !== '')     { $conditions[] = "createdAt <= ?$i"; $bind[] = $dateTo   . ' 23:59:59'; $i++; }
        if ($search !== '') {
            $conditions[] = "(description LIKE ?$i OR actorName LIKE ?" . ($i + 1) . ")";
            $bind[] = '%' . $search . '%';
            $bind[] = '%' . $search . '%';
            $i += 2;
        }

        $where = $conditions ? implode(' AND ', $conditions) : '1=1';

        $total = (int) AuditLog::count([
            'conditions' => $where,
            'bind'       => $bind,
        ]);

        $logs = AuditLog::find([
            'conditions' => $where,
            'bind'       => $bind,
            'order'      => 'createdAt DESC',
            'limit'      => $perPage,
            'offset'     => ($page - 1) * $perPage,
        ]);

        $data = [];
        foreach ($logs as $log) $data[] = $this->format($log);

        return [
            'data' => $data,
            'meta' => [
                'page'       => $page,
                'perPage'    => $perPage,
                'total'      => $total,
                'totalPages' => (int) ceil($total / $perPage),
            ],
        ];
    }

    public function show($id)
    {
        $log = AuditLog::findFirst([
            'conditions' => 'id = ?0',
            'bind'       => [$id],
        ]);

        if (!$log) {
            $this->response->setStatusCode(404);
            return ['error' => 'Log tidak ditemukan'];
        }

        return $this->format($log);
    }
}
