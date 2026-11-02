<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Admin;
use Firebase\JWT\JWT;

class AdminAuthController extends Controller
{
    private function formatAdminResponse($admin)
    {
        $data = $admin->toArray();
        unset($data['password']);

        $role = \App\Models\AdminRole::findFirst([
            'conditions' => 'name = ?0 AND deletedAt IS NULL',
            'bind' => [$admin->role]
        ]);
        
        $permissions = [];
        if ($role) {
            $permissions = is_string($role->permissions) ? json_decode($role->permissions, true) : $role->permissions;
        }
        $data['permissions'] = $permissions ?: [];

        return $data;
    }

    public function login()
    {
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $emailOrUsername = $request['emailOrUsername'] ?? $request['email'] ?? '';
        $password = $request['password'] ?? '';

        if (!$emailOrUsername || !$password) {
            $this->response->setStatusCode(400);
            return ['message' => 'Email/Username dan kata sandi wajib diisi'];
        }

        $key = strtolower(trim($emailOrUsername));
        $admin = Admin::findFirst([
            'conditions' => 'deletedAt IS NULL AND (email = ?0 OR username = ?1)',
            'bind' => [$key, $key]
        ]);

        if (!$admin || !password_verify($password, $admin->password)) {
            $this->response->setStatusCode(401);
            return ['message' => 'Kredensial tidak valid'];
        }

        $secret = $this->di->get('config')['jwt_secret'];
        $payload = [
            'id'    => $admin->id,
            'email' => $admin->email,
            'role'  => $admin->role,
            'v'     => $admin->tokenVersion ?? 1,
            'src'   => 'admin',  // penanda bahwa token berasal dari tabel Admin
            'exp'   => time() + (3 * 60 * 60) // 3 jam
        ];
        $token = JWT::encode($payload, $secret, 'HS256');

        $this->di->getShared('auditLog')->log([
            'source'     => 'cms',
            'action'     => 'login',
            'actor'      => ['id' => $admin->id, 'type' => 'admin', 'name' => $admin->nama, 'role' => $admin->role],
            'entityType' => 'Admin',
            'entityId'   => $admin->id,
            'description' => "Admin {$admin->nama} login ke CMS",
        ]);

        $this->response->setStatusCode(200);
        return [
            'message' => 'Masuk berhasil',
            'token'   => $token,
            'user'    => $this->formatAdminResponse($admin)
        ];
    }

    public function me()
    {
        $userId   = $this->di->getShared('userId');
        $userRole = $this->di->getShared('userRole');

        if (!$userId) {
            $this->response->setStatusCode(401);
            return ['message' => 'Pengguna tidak terautentikasi'];
        }

        $admin = Admin::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$userId]
        ]);

        if (!$admin) {
            $this->response->setStatusCode(404);
            return ['message' => 'Admin tidak ditemukan'];
        }

        return ['user' => $this->formatAdminResponse($admin)];
    }

    public function logout()
    {
        $userId   = $this->di->getShared('userId');
        $userRole = $this->di->getShared('userRole');

        if ($userId) {
            $admin = Admin::findFirst([
                'conditions' => 'id = ?0 AND deletedAt IS NULL',
                'bind' => [$userId]
            ]);

            $name = $admin ? $admin->nama : 'Admin';
            $role = $admin ? $admin->role : ($userRole ?: 'Admin');

            $this->di->getShared('auditLog')->log([
                'source'      => 'cms',
                'action'      => 'logout',
                'actor'       => ['id' => $userId, 'type' => 'admin', 'name' => $name, 'role' => $role],
                'entityType'  => 'Admin',
                'entityId'    => $userId,
                'description' => "Admin {$name} logout dari CMS",
            ]);
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Berhasil keluar'];
    }
}
