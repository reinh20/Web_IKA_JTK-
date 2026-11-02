<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddKategoriToBerita extends AbstractMigration
{
    public function up(): void
    {
        $berita = $this->table('Berita');
        if (!$berita->hasColumn('kategori')) {
            $berita->addColumn('kategori', 'string', [
                'limit'   => 50,
                'null'    => true,
                'default' => 'Pengumuman',
                'after'   => 'judul',
            ])->update();
        }
    }

    public function down(): void
    {
        $berita = $this->table('Berita');
        if ($berita->hasColumn('kategori')) {
            $berita->removeColumn('kategori')->update();
        }
    }
}
