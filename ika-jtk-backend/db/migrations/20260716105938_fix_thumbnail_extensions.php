<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class FixThumbnailExtensions extends AbstractMigration
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
    public function up(): void
    {
        $this->execute('UPDATE "Berita" SET "bannerThumbnailUrl" = REPLACE("bannerThumbnailUrl", \'_thumb.png\', \'_thumb.jpg\') WHERE "bannerThumbnailUrl" LIKE \'%_thumb.png%\'');
        $this->execute('UPDATE "Berita" SET "bannerThumbnailUrl" = REPLACE("bannerThumbnailUrl", \'_thumb.webp\', \'_thumb.jpg\') WHERE "bannerThumbnailUrl" LIKE \'%_thumb.webp%\'');

        $this->execute('UPDATE "Agenda" SET "bannerThumbnailUrl" = REPLACE("bannerThumbnailUrl", \'_thumb.png\', \'_thumb.jpg\') WHERE "bannerThumbnailUrl" LIKE \'%_thumb.png%\'');
        $this->execute('UPDATE "Agenda" SET "bannerThumbnailUrl" = REPLACE("bannerThumbnailUrl", \'_thumb.webp\', \'_thumb.jpg\') WHERE "bannerThumbnailUrl" LIKE \'%_thumb.webp%\'');

        $this->execute('UPDATE "Loker" SET "logoThumbnailUrl" = REPLACE("logoThumbnailUrl", \'_thumb.png\', \'_thumb.jpg\') WHERE "logoThumbnailUrl" LIKE \'%_thumb.png%\'');
        $this->execute('UPDATE "Loker" SET "logoThumbnailUrl" = REPLACE("logoThumbnailUrl", \'_thumb.webp\', \'_thumb.jpg\') WHERE "logoThumbnailUrl" LIKE \'%_thumb.webp%\'');
    }
}
