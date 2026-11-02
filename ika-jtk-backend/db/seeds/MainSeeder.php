<?php

declare(strict_types=1);

use Phinx\Seed\AbstractSeed;

/**
 * MainSeeder — entry point yang menjalankan semua seeder secara berurutan.
 *
 * Urutan penting:
 *   1. AdminRoleSeeder                — role harus ada sebelum Admin (FK role -> AdminRole.name)
 *   2. AdminRoleExtraPermissionsSeeder — append permission fitur menyusul (alumni grafis, settings)
 *   3. DefaultAdminSeeder
 *   4. PortalConfigSeeder
 */
class MainSeeder extends AbstractSeed
{
    public function getDependencies(): array
    {
        return [
            'AdminRoleSeeder',
            'AdminRoleExtraPermissionsSeeder',
            'DefaultAdminSeeder',
            'PortalConfigSeeder',
        ];
    }

    public function run(): void
    {
        // Dijalankan via dependency, tidak perlu isi manual.
    }
}
