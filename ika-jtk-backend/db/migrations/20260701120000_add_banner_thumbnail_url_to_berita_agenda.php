<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddBannerThumbnailUrlToBeritaAgenda extends AbstractMigration
{
    public function change(): void
    {
        $berita = $this->table('Berita');
        if (!$berita->hasColumn('bannerThumbnailUrl')) {
            $berita->addColumn('bannerThumbnailUrl', 'string', [
                'limit' => 255,
                'null'  => true,
                'after' => 'bannerUrl',
            ])->update();
        }

        $agenda = $this->table('Agenda');
        if (!$agenda->hasColumn('bannerThumbnailUrl')) {
            $agenda->addColumn('bannerThumbnailUrl', 'string', [
                'limit' => 255,
                'null'  => true,
                'after' => 'bannerUrl',
            ])->update();
        }
    }
}
