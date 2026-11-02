<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddTagsAndLogoThumbToBeritaAgendaLoker extends AbstractMigration
{
    public function change(): void
    {
        $berita = $this->table('Berita');
        if (!$berita->hasColumn('tags')) {
            $berita->addColumn('tags', 'text', [
                'null' => true,
                'after' => 'kategori',
            ])->update();
        }

        $agenda = $this->table('Agenda');
        if (!$agenda->hasColumn('tags')) {
            $agenda->addColumn('tags', 'text', [
                'null' => true,
                'after' => 'lokasi',
            ])->update();
        }

        $loker = $this->table('Loker');
        if (!$loker->hasColumn('logoThumbnailUrl')) {
            $loker->addColumn('logoThumbnailUrl', 'string', [
                'limit' => 255,
                'null' => true,
                'after' => 'logoUrl',
            ])->update();
        }
        if (!$loker->hasColumn('tags')) {
            $loker->addColumn('tags', 'text', [
                'null' => true,
                'after' => 'deskripsi',
            ])->update();
        }
    }
}
