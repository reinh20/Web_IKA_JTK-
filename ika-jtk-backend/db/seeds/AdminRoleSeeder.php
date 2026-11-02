<?php

declare(strict_types=1);

use Phinx\Seed\AbstractSeed;

class AdminRoleSeeder extends AbstractSeed
{
    public function run(): void
    {
        $table = $this->table('AdminRole');
        
        $roles = [
            [
                'name' => 'Super Admin',
                'description' => 'Memiliki akses penuh ke seluruh sistem.',
                // Permission alumnigrafis_* dan settings_* di-append oleh
                // AdminRoleExtraPermissionsSeeder (dipisah karena fitur menyusul).
                'permissions' => json_encode([
                    'alumni_view', 'alumni_edit',
                    'berita_view', 'berita_edit',
                    'agenda_view', 'agenda_edit',
                    'loker_view', 'loker_edit',
                    'testimoni_view', 'testimoni_edit',
                    'pemilu_view', 'pemilu_edit',
                    'roles_view', 'roles_edit',
                    'users_view', 'users_edit',
                    'audit_log_view',
                ]),
                'isSystem' => 1,
            ],
            [
                // Role bawaan non-superadmin: bisa mengelola konten,
                // tapi tidak dapat mengatur role & user admin.
                'name' => 'Admin',
                'description' => 'Dapat mengelola konten (alumni, alumni grafis, berita, agenda, loker, testimoni, pemilu).',
                // Permission alumnigrafis_* di-append oleh AdminRoleExtraPermissionsSeeder.
                'permissions' => json_encode([
                    'alumni_view', 'alumni_edit',
                    'berita_view', 'berita_edit',
                    'agenda_view', 'agenda_edit',
                    'loker_view', 'loker_edit',
                    'testimoni_view', 'testimoni_edit',
                    'pemilu_view', 'pemilu_edit',
                ]),
                'isSystem' => 1,
            ],
            [
                // Role bawaan hanya-lihat.
                'name' => 'Editor',
                'description' => 'Dapat melihat & mengubah berita dan agenda saja.',
                'permissions' => json_encode([
                    'berita_view', 'berita_edit',
                    'agenda_view', 'agenda_edit',
                ]),
                'isSystem' => 1,
            ],
        ];

        foreach ($roles as $role) {
            $row = $this->fetchRow("SELECT * FROM \"AdminRole\" WHERE name = '{$role['name']}'");
            if (empty($row)) {
                $isSys = $role['isSystem'] ? 'true' : 'false';
                // id adalah string (UUID/hex) yang di-generate manual,
                // konsisten dengan konvensi model (lihat migration
                // 20260702120000_fix_admin_role_id_to_string).
                $id = bin2hex(random_bytes(16));
                $this->execute("INSERT INTO \"AdminRole\" (id, name, description, permissions, \"isSystem\") VALUES ('{$id}', '{$role['name']}', '{$role['description']}', '{$role['permissions']}', {$isSys})");
            } else {
                $this->execute("UPDATE \"AdminRole\" SET permissions = '{$role['permissions']}' WHERE name = '{$role['name']}'");
            }
        }
    }
}
