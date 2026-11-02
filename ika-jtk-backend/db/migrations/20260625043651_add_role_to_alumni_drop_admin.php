<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddRoleToAlumniDropAdmin extends AbstractMigration
{
    /**
     * Change Method.
     *
     * Write your reversible migrations using this method.
     *
     * More information on writing migrations is available here:
     * https://book.cakephp.org/phinx/0/en/migrations.html#the-change-method
     *
     * Remember to call "create()" or "update()" and NOT "save()" when working
     * with the Table class.
     */
    public function change(): void
    {
        // Tambahkan kolom role ke tabel Alumni
        $alumni = $this->table('Alumni');
        if (!$alumni->hasColumn('role')) {
            $alumni->addColumn('role', 'string', [
                'limit' => 50,
                'default' => 'anggota',
                'null' => false,
                'after' => 'status'
            ])
            ->update();
        }

        // Hapus tabel Admin jika ada
        if ($this->hasTable('Admin')) {
            $this->table('Admin')->drop()->save();
        }
    }
}
