<?php

declare(strict_types=1);

use Phinx\Seed\AbstractSeed;

/**
 * Seed akun Super Admin default.
 * Idempoten: hanya insert jika tabel "Admin" masih kosong.
 *
 * Kredensial default: admin@ikajtk.id / admin123
 */
class DefaultAdminSeeder extends AbstractSeed
{
    public function run(): void
    {
        $count = (int) $this->fetchRow('SELECT COUNT(*) AS c FROM "Admin"')['c'];
        if ($count > 0) {
            return;
        }

        $this->table('Admin')->insert([
            'id'           => bin2hex(random_bytes(16)),
            'nama'         => 'Super Admin',
            'email'        => 'admin@ikajtk.id',
            'username'     => 'admin',
            'password'     => password_hash('admin123', PASSWORD_BCRYPT),
            'role'         => 'Super Admin',
            'tokenVersion' => 1,
            'createdAt'    => date('Y-m-d H:i:s'),
        ])->saveData();
    }
}
