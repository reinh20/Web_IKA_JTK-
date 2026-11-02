<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Admin;

class AdminUsersController extends Controller
{
    private function formatAdminResponse($admin)
    {
        $data = $admin->toArray();
        unset($data['password']);
        return $data;
    }

    public function index()
    {
        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = $this->request->getQuery('search', 'string', '');

        $conditions = 'deletedAt IS NULL';
        $bind = [];

        if ($search !== '') {
            $conditions .= ' AND (LOWER(nama) LIKE LOWER(:search:) OR LOWER(email) LIKE LOWER(:search:) OR LOWER(username) LIKE LOWER(:search:))';
            $bind['search'] = '%' . $search . '%';
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => 'createdAt DESC'
        ];

        if ($page !== null) {
            $total = Admin::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $admins = Admin::find($queryOpts);
            $result = [];
            foreach ($admins as $admin) {
                $result[] = $this->formatAdminResponse($admin);
            }

            return [
                'data' => $result,
                'total' => $total,
            ];
        }

        // Fallback
        $admins = Admin::find($queryOpts);
        $result = [];
        foreach ($admins as $admin) {
            $result[] = $this->formatAdminResponse($admin);
        }

        return $result;
    }

    public function show($id)
    {
        $admin = Admin::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$admin) {
            $this->response->setStatusCode(404);
            return ['error' => 'Admin tidak ditemukan'];
        }

        return $this->formatAdminResponse($admin);
    }

    public function create()
    {
        $data = $this->request->getJsonRawBody(true);

        if (empty($data['nama']) || empty($data['email']) || empty($data['username']) || empty($data['password']) || empty($data['role'])) {
            $this->response->setStatusCode(400);
            return ['error' => 'Semua field wajib diisi'];
        }

        if (preg_match('/\s/', $data['username'])) {
            $this->response->setStatusCode(400);
            return ['error' => 'Username tidak boleh mengandung spasi'];
        }

        if (preg_match('/\s/', $data['password'])) {
            $this->response->setStatusCode(400);
            return ['error' => 'Password tidak boleh mengandung spasi'];
        }

        // Check unique email & username
        $existing = Admin::findFirst([
            'conditions' => 'email = ?0 OR username = ?1',
            'bind' => [$data['email'], $data['username']]
        ]);

        if ($existing) {
            $this->response->setStatusCode(400);
            return ['error' => 'Email atau Username sudah digunakan'];
        }

        // Prevent creating another Super Admin
        if ($data['role'] === 'Super Admin') {
            $superAdminCount = Admin::count(['conditions' => 'deletedAt IS NULL AND role = ?0', 'bind' => ['Super Admin']]);
            if ($superAdminCount >= 1) {
                $this->response->setStatusCode(400);
                return ['error' => 'Hanya boleh ada 1 Super Admin di dalam sistem'];
            }
        }

        $admin = new Admin();
        $admin->id = bin2hex(random_bytes(16));
        $admin->nama = $data['nama'];
        $admin->email = $data['email'];
        $admin->username = $data['username'];
        $admin->password = password_hash($data['password'], PASSWORD_BCRYPT);
        $admin->role = $data['role'];
        $admin->createdAt = date('Y-m-d H:i:s');

        if (!$admin->save()) {
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menyimpan admin'];
        }

        $this->response->setStatusCode(201);
        return $this->formatAdminResponse($admin);
    }

    public function update($id)
    {
        $userRole = $this->di->getShared('userRole');
        if ($userRole !== 'Super Admin') {
            $this->response->setStatusCode(403);
            return ['error' => 'Akses ditolak'];
        }

        $admin = Admin::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$admin) {
            $this->response->setStatusCode(404);
            return ['error' => 'Admin tidak ditemukan'];
        }

        $data = $this->request->getJsonRawBody(true);

        if (!empty($data['nama'])) $admin->nama = $data['nama'];
        
        if (!empty($data['role'])) {
            // Prevent changing a Super Admin's role to something else
            if ($admin->role === 'Super Admin' && $data['role'] !== 'Super Admin') {
                $this->response->setStatusCode(400);
                return ['error' => 'Role Super Admin tidak dapat diubah ke role lain'];
            }
            
            // Prevent changing another user's role to Super Admin if one already exists
            if ($admin->role !== 'Super Admin' && $data['role'] === 'Super Admin') {
                $superAdminCount = Admin::count(['conditions' => 'deletedAt IS NULL AND role = ?0', 'bind' => ['Super Admin']]);
                if ($superAdminCount >= 1) {
                    $this->response->setStatusCode(400);
                    return ['error' => 'Hanya boleh ada 1 Super Admin di dalam sistem'];
                }
            }
            $admin->role = $data['role'];
        }

        if (!empty($data['email']) && $data['email'] !== $admin->email) {
            $checkEmail = Admin::findFirst(['conditions' => 'email = ?0', 'bind' => [$data['email']]]);
            if ($checkEmail) {
                $this->response->setStatusCode(400);
                return ['error' => 'Email sudah digunakan'];
            }
            $admin->email = $data['email'];
        }

        if (!empty($data['username']) && $data['username'] !== $admin->username) {
            if (preg_match('/\s/', $data['username'])) {
                $this->response->setStatusCode(400);
                return ['error' => 'Username tidak boleh mengandung spasi'];
            }
            $checkUsername = Admin::findFirst(['conditions' => 'username = ?0', 'bind' => [$data['username']]]);
            if ($checkUsername) {
                $this->response->setStatusCode(400);
                return ['error' => 'Username sudah digunakan'];
            }
            $admin->username = $data['username'];
        }

        if (!empty($data['password'])) {
            if (preg_match('/\s/', $data['password'])) {
                $this->response->setStatusCode(400);
                return ['error' => 'Password tidak boleh mengandung spasi'];
            }
            $admin->password = password_hash($data['password'], PASSWORD_BCRYPT);
            $admin->tokenVersion = ($admin->tokenVersion ?? 1) + 1; // invalidate old tokens
        }

        if (!$admin->save()) {
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal memperbarui admin'];
        }

        return $this->formatAdminResponse($admin);
    }

    public function delete($id)
    {
        $userId = $this->di->getShared('userId');

        if ($id === $userId) {
            $this->response->setStatusCode(400);
            return ['error' => 'Tidak dapat menghapus akun Anda sendiri'];
        }

        $admin = Admin::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$admin) {
            $this->response->setStatusCode(404);
            return ['error' => 'Admin tidak ditemukan'];
        }

        if ($admin->role === 'Super Admin') {
            $this->response->setStatusCode(400);
            return ['error' => 'Akun Super Admin tidak dapat dihapus'];
        }

        $admin->deletedAt = date('Y-m-d H:i:s');
        if ($admin->save() === false) {
            $messages = $admin->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus.', 'detail' => implode(', ', $messages)];
        }

        return ['message' => 'Admin berhasil dihapus'];
    }
}
