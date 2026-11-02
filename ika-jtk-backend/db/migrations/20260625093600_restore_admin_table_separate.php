<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * Kembalikan tabel Admin yang terpisah dari Alumni.
 *
 * - Buat tabel Admin dengan kolom lengkap (id, nama, email, username, password, role, avatarUrl, tokenVersion, createdAt)
 * - Hapus kolom `role` dan `tokenVersion` dari tabel Alumni (admin bukan lagi alumni)
 */
final class RestoreAdminTableSeparate extends AbstractMigration
{
    public function up(): void
    {
        // Buat tabel Admin jika belum ada
        if (!$this->hasTable('Admin')) {
            $this->table('Admin', ['id' => false, 'primary_key' => 'id'])
                ->addColumn('id', 'string', ['limit' => 255])
                ->addColumn('nama', 'string', ['limit' => 255])
                ->addColumn('email', 'string', ['limit' => 255])
                ->addColumn('username', 'string', ['limit' => 255])
                ->addColumn('password', 'string', ['limit' => 255])
                ->addColumn('role', 'string', ['limit' => 50, 'default' => 'Super Admin', 'null' => true])
                ->addColumn('avatarUrl', 'string', ['limit' => 255, 'null' => true])
                ->addColumn('tokenVersion', 'integer', ['default' => 1, 'null' => true])
                ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
                ->addIndex('email', ['unique' => true])
                ->addIndex('username', ['unique' => true])
                ->create();
        }

        // Hapus kolom role dari Alumni (admin & alumni kini benar-benar terpisah)
        $alumni = $this->table('Alumni');
        if ($alumni->hasColumn('role')) {
            $alumni->removeColumn('role')->update();
        }
        if ($alumni->hasColumn('tokenVersion')) {
            $alumni->removeColumn('tokenVersion')->update();
        }
    }

    public function down(): void
    {
        // Rollback: hapus tabel Admin, kembalikan kolom role & tokenVersion ke Alumni
        if ($this->hasTable('Admin')) {
            $this->table('Admin')->drop()->save();
        }

        $alumni = $this->table('Alumni');
        if (!$alumni->hasColumn('role')) {
            $alumni->addColumn('role', 'string', [
                'limit'   => 50,
                'default' => 'anggota',
                'null'    => false,
                'after'   => 'status',
            ])->update();
        }
        if (!$alumni->hasColumn('tokenVersion')) {
            $alumni->addColumn('tokenVersion', 'integer', [
                'default' => 1,
                'null'    => true,
            ])->update();
        }
    }
}
