<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\AdminRole;

class AdminRoleController extends Controller
{
    private function checkSuperAdmin()
    {
        $userRole = $this->di->getShared('userRole');
        if ($userRole !== 'Super Admin') {
            $this->response->setStatusCode(403);
            return false;
        }
        return true;
    }

    public function index()
    {
        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = $this->request->getQuery('search', 'string', '');

        $conditions = 'deletedAt IS NULL';
        $bind = [];

        if ($search !== '') {
            $conditions .= ' AND (LOWER(name) LIKE LOWER(:search:) OR LOWER(description) LIKE LOWER(:search:))';
            $bind['search'] = '%' . $search . '%';
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => 'name ASC'
        ];

        if ($page !== null) {
            $total = AdminRole::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $roles = AdminRole::find($queryOpts);
            return [
                'data' => $roles->toArray(),
                'total' => $total,
            ];
        }

        $roles = AdminRole::find($queryOpts);
        return $roles->toArray();
    }

    public function create()
    {
        if (!$this->checkSuperAdmin()) {
            return ['error' => 'Akses ditolak'];
        }

        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        $name = trim($request['name'] ?? '');
        $description = trim($request['description'] ?? '');
        $permissions = $request['permissions'] ?? [];

        if (empty($name)) {
            $this->response->setStatusCode(400);
            return ['error' => 'Nama role harus diisi'];
        }

        $existing = AdminRole::findFirst([
            'conditions' => 'name = ?0 AND deletedAt IS NULL',
            'bind' => [$name]
        ]);

        if ($existing) {
            $this->response->setStatusCode(400);
            return ['error' => 'Role dengan nama tersebut sudah ada'];
        }

        $role = new AdminRole();
        $role->name = $name;
        $role->description = $description;
        $role->permissions = $permissions;
        $role->isSystem = false;

        if ($role->save() === false) {
            $this->response->setStatusCode(500);
            return [
                'error' => 'Gagal membuat role',
                'detail' => implode(', ', array_map(fn($m) => (string) $m, $role->getMessages())),
            ];
        }

        return ['message' => 'Role berhasil dibuat', 'role' => $role];
    }

    public function update($name)
    {
        if (!$this->checkSuperAdmin()) {
            return ['error' => 'Akses ditolak'];
        }

        $name = urldecode($name);
        $role = AdminRole::findFirst([
            'conditions' => 'name = ?0 AND deletedAt IS NULL',
            'bind' => [$name]
        ]);

        if (!$role) {
            $this->response->setStatusCode(404);
            return ['error' => 'Role tidak ditemukan'];
        }

        if ($role->isSystem) {
            $this->response->setStatusCode(400);
            return ['error' => 'Role bawaan sistem tidak dapat diubah (hanya dapat dilihat)'];
        }

        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $prevDescription = $role->description;
        $prevPermissions = is_array($role->permissions) ? $role->permissions : (json_decode((string) $role->permissions, true) ?: []);

        if (isset($request['description'])) {
            $role->description = trim($request['description']);
        }
        if (isset($request['permissions'])) {
            $role->permissions = $request['permissions'];
        }

        $newPermissions = isset($request['permissions']) && is_array($request['permissions']) ? $request['permissions'] : $prevPermissions;
        $permissionsChanged = isset($request['permissions']) && (array_values($prevPermissions) !== array_values($newPermissions));

        // Kalau perubahan hanya di permissions, suppress auto-log "update" dari trait supaya
        // hanya muncul entri "permission_change" yang lebih deskriptif di bawah.
        if ($permissionsChanged) {
            $this->di->getShared('auditLog')->skipNextChange('AdminRole', $role->name);
        }

        if ($role->save() === false) {
            $this->response->setStatusCode(500);
            return [
                'error' => 'Gagal memperbarui role',
                'detail' => implode(', ', array_map(fn($m) => (string) $m, $role->getMessages())),
            ];
        }

        if ($permissionsChanged) {
            $added   = array_values(array_diff($newPermissions, $prevPermissions));
            $removed = array_values(array_diff($prevPermissions, $newPermissions));
            $this->di->getShared('auditLog')->log([
                'action'      => 'permission_change',
                'entityType'  => 'AdminRole',
                'entityId'    => $role->name,
                'description' => "Ubah permission role {$role->name}",
                'changes'     => ['before' => ['permissions' => array_values($prevPermissions)], 'after' => ['permissions' => array_values($newPermissions)]],
                'metadata'    => ['added' => $added, 'removed' => $removed],
            ]);
        }

        return ['message' => 'Role berhasil diperbarui', 'role' => $role];
    }

    public function delete($name)
    {
        if (!$this->checkSuperAdmin()) {
            return ['error' => 'Akses ditolak'];
        }

        $name = urldecode($name);
        $role = AdminRole::findFirst([
            'conditions' => 'name = ?0 AND deletedAt IS NULL',
            'bind' => [$name]
        ]);

        if (!$role) {
            $this->response->setStatusCode(404);
            return ['error' => 'Role tidak ditemukan'];
        }

        if ($role->isSystem) {
            $this->response->setStatusCode(400);
            return ['error' => 'Role bawaan sistem tidak dapat dihapus'];
        }

        // Check if there are users with this role
        $adminCount = \App\Models\Admin::count([
            'conditions' => 'deletedAt IS NULL AND role = ?0',
            'bind' => [$name]
        ]);

        if ($adminCount > 0) {
            $this->response->setStatusCode(400);
            return ['error' => "Role ini tidak dapat dihapus karena masih digunakan oleh $adminCount admin"];
        }

        $role->deletedAt = date('Y-m-d H:i:s');
        if ($role->save() === false) {
            $messages = $role->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus.', 'detail' => implode(', ', $messages)];
        }

        return ['message' => 'Role berhasil dihapus'];
    }
}
