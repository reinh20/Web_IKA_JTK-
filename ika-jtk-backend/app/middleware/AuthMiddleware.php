<?php

namespace App\Middleware;

use Phalcon\Events\Event;
use Phalcon\Mvc\Micro;
use Phalcon\Mvc\Micro\MiddlewareInterface;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class AuthMiddleware implements MiddlewareInterface
{
    public function beforeExecuteRoute(Event $event, Micro $app)
    {
        if ($app->request->getMethod() === 'OPTIONS') {
            return true;
        }
        $unprotectedRoutes = [
            '/api/auth/login',
            '/api/auth/register',
            '/api/auth/check-unique',
            '/api/auth/verify-email',
            '/api/auth/resend-otp',
            '/api/admin/auth/login',
            '/api/elections',
            '/api/elections/{id}',
            '/api/elections/{id}/summary',
            '/api/auth/forgot-password',
            '/api/auth/reset-password',
            '/docs'
        ];

        $matchedRoute = $app->getRouter()->getMatchedRoute();
        if (!$matchedRoute) {
            return true;
        }

        $currentRoute = $matchedRoute->getPattern();

        if (in_array($currentRoute, $unprotectedRoutes) || (strpos($currentRoute, '/api/portal') === 0 && $app->request->getMethod() === 'GET' && strpos($currentRoute, '/api/portal/lamaran') === false) || (strpos($currentRoute, '/api/testimoni') === 0 && $app->request->getMethod() === 'GET' && $currentRoute !== '/api/testimoni/me')) {
            return true;
        }

        // Removed temporary bypass so token is decoded and userId is set

        // Untuk rute lain, butuh JWT Token
        $authHeader = $app->request->getHeader('Authorization');
        if (!$authHeader || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
            $this->sendError($app, 401, 'Akses ditolak: Token tidak ditemukan');
            return false;
        }

        $token = $matches[1];
        $secret = $app->getDI()->get('config')['jwt_secret'];

        try {
            $decoded = JWT::decode($token, new Key($secret, 'HS256'));
            
            // Cek role untuk route admin
            $userRole = $decoded->role ?? 'anggota';
            $tokenSrc = $decoded->src ?? 'alumni';
            
            if (strpos($currentRoute, '/api/admin') === 0) {
                if ($tokenSrc !== 'admin') {
                    $this->sendError($app, 403, 'Akses ditolak: Anda tidak memiliki akses ke panel Admin');
                    return false;
                }

                $adminRoleObj = \App\Models\AdminRole::findFirst([
                    'conditions' => 'name = ?0',
                    'bind' => [$userRole]
                ]);

                if (!$adminRoleObj) {
                    $this->sendError($app, 403, 'Akses ditolak: Role Anda tidak dikenali');
                    return false;
                }

                $module = '';
                if (strpos($currentRoute, '/api/admin/alumni-grafis') === 0) $module = 'alumnigrafis';
                elseif (strpos($currentRoute, '/api/admin/alumni') === 0) $module = 'alumni';
                elseif (strpos($currentRoute, '/api/admin/berita') === 0) $module = 'berita';
                elseif (strpos($currentRoute, '/api/admin/agenda') === 0) $module = 'agenda';
                elseif (strpos($currentRoute, '/api/admin/loker') === 0) $module = 'loker';
                elseif (strpos($currentRoute, '/api/admin/testimoni') === 0) $module = 'testimoni';
                elseif (strpos($currentRoute, '/api/admin/elections') === 0) $module = 'pemilu';
                elseif (strpos($currentRoute, '/api/admin/users') === 0) $module = 'users';
                elseif (strpos($currentRoute, '/api/admin/roles') === 0) $module = 'roles';
                elseif (strpos($currentRoute, '/api/admin/audit-logs') === 0) $module = 'audit_log';
                
                if ($module !== '') {
                    $permissions = is_string($adminRoleObj->permissions) ? json_decode($adminRoleObj->permissions, true) : $adminRoleObj->permissions;
                    if (!is_array($permissions)) $permissions = [];
                    
                    if ($module === 'roles' && $app->request->getMethod() === 'GET' && in_array('users_view', $permissions)) {
                        // Allow fetching roles for users list mapping
                        $reqPerm = 'users_view'; 
                    } else {
                        $method = $app->request->getMethod();
                        $reqPerm = in_array($method, ['POST', 'PUT', 'DELETE']) ? $module . '_edit' : $module . '_view';
                    }
                    
                    if (!in_array($reqPerm, $permissions)) {
                        $this->sendError($app, 403, "Akses ditolak: Anda tidak memiliki izin '$reqPerm' untuk modul ini");
                        return false;
                    }
                }
            }

            // Validasi tokenVersion: gunakan tabel Admin atau Alumni sesuai sumber token
            $tokenSrc     = $decoded->src ?? 'alumni';
            $tokenVersion = $decoded->v ?? 1;

            if ($tokenSrc === 'admin') {
                $user = \App\Models\Admin::findFirst([
                    'conditions' => 'id = ?0',
                    'bind'       => [$decoded->id ?? '']
                ]);
                if (!$user) {
                    $this->sendError($app, 401, 'Akses ditolak: Akun admin tidak ditemukan');
                    return false;
                }
            } else {
                $user = \App\Models\Alumni::findFirst([
                    'conditions' => 'id = ?0',
                    'bind'       => [$decoded->id ?? '']
                ]);
                if (!$user) {
                    $this->sendError($app, 401, 'Akses ditolak: Akun tidak ditemukan');
                    return false;
                }
                if ($user->status === \App\Enums\AlumniStatus::INACTIVE->value) {
                    $this->sendError($app, 403, 'Akun Anda telah dinonaktifkan. Silakan hubungi admin IKA JTK.');
                    return false;
                }
            }

            if (($user->tokenVersion ?? 1) > $tokenVersion) {
                $this->sendError($app, 401, 'Akses ditolak: Sesi Anda telah berakhir (mungkin karena kata sandi diubah). Silakan login kembali.');
                return false;
            }

            // Simpan userId dan userRole di memory agar bisa dibaca controller
            $app->getDI()->setShared('userId', function() use ($decoded) {
                return $decoded->id ?? null;
            });
            $app->getDI()->setShared('userRole', function() use ($decoded) {
                return $decoded->role ?? null;
            });
            return true;
        } catch (\Exception $e) {
            $this->sendError($app, 401, 'Akses ditolak: Token tidak valid (' . $e->getMessage() . ')');
            return false;
        }
    }

    public function call(Micro $app)
    {
        return true;
    }

    private function sendError(Micro $app, int $code, string $message)
    {
        $app->response->setStatusCode($code, 'Unauthorized');
        
        $origin = $app->request->getHeader('ORIGIN') ? $app->request->getHeader('ORIGIN') : '*';
        $app->response->setHeader('Access-Control-Allow-Origin', $origin);
        $app->response->setHeader('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
        $app->response->setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Range, Content-Disposition, Content-Type, Authorization');
        $app->response->setHeader('Access-Control-Allow-Credentials', 'true');
        
        $app->response->setContentType('application/json', 'UTF-8');
        $app->response->setContent(json_encode([
            'status' => 'error',
            'message' => $message
        ]));
        $app->response->send();
    }
}
