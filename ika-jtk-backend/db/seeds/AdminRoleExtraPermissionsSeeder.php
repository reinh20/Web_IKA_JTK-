<?php

declare(strict_types=1);

use Phinx\Seed\AbstractSeed;

/**
 * Menambahkan permission fitur yang menyusul (alumni grafis & settings)
 * ke role bawaan tanpa menyentuh permission lain.
 *
 * Idempotent: kalau permission sudah ada, tidak melakukan UPDATE.
 */
class AdminRoleExtraPermissionsSeeder extends AbstractSeed
{
    public function getDependencies(): array
    {
        return ['AdminRoleSeeder'];
    }

    public function run(): void
    {
        $extras = [
            'Super Admin' => [
                'alumnigrafis_view', 'alumnigrafis_edit',
                'settings_view', 'settings_edit',
            ],
            'Admin' => [
                'alumnigrafis_view', 'alumnigrafis_edit',
            ],
        ];

        foreach ($extras as $roleName => $perms) {
            $row = $this->fetchRow("SELECT permissions FROM \"AdminRole\" WHERE name = '{$roleName}'");
            if (empty($row)) {
                continue;
            }

            $current = json_decode((string) ($row['permissions'] ?? '[]'), true) ?: [];
            $merged  = array_values(array_unique(array_merge($current, $perms)));

            if ($merged === $current) {
                continue;
            }

            $encoded = json_encode($merged);
            $this->execute("UPDATE \"AdminRole\" SET permissions = '{$encoded}' WHERE name = '{$roleName}'");
        }
    }
}
