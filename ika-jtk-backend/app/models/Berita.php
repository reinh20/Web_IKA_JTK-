<?php

namespace App\Models;

use Phalcon\Mvc\Model;
use App\Traits\TracksStorageFields;
use App\Traits\LogsChanges;

class Berita extends Model
{
    use TracksStorageFields;
    use LogsChanges;

    protected function auditEntityType(): string { return 'Berita'; }

    public $id;
    public $noBerita;
    public $judul;
    public $konten;
    public $bannerUrl;
    public $bannerThumbnailUrl;
    public $kategori;
    public $tags;
    public $authorId;
    public $authorNama;
    public $authorRole;
    public $authorAvatarUrl;
    public $highlightedAlumniId;
    public $status = 'Draft';
    public $createdAt;
    public $updatedAt;
    public $deletedAt;
    public $publishedAt;

    public function initialize()
    {
        $this->setSource("Berita");
        $this->keepSnapshots(true);
    }

    // authorAvatarUrl adalah snapshot dari Alumni.avatarUrl — tidak owned, jangan track.
    protected function trackedStorageFields(): array
    {
        return ['bannerUrl', 'bannerThumbnailUrl'];
    }

    public function beforeUpdate()
    {
        $this->cleanupOldStorageOnUpdate();
    }

    public function beforeDelete()
    {
        $this->cleanupAllStorageOnDelete();
    }


    public function beforeValidationOnCreate()
    {

        if (empty($this->id)) {
            $this->id = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                mt_rand(0, 0xffff), mt_rand(0, 0xffff),
                mt_rand(0, 0xffff),
                mt_rand(0, 0x0fff) | 0x4000,
                mt_rand(0, 0x3fff) | 0x8000,
                mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
            );
        }
        if (empty($this->noBerita)) {
            $today = date('Ymd');
            $last = self::findFirst([
                'conditions' => 'noBerita LIKE ?0',
                'bind' => ["$today%"],
                'order' => 'noBerita DESC'
            ]);
            $seq = $last ? ((int)substr($last->noBerita, -4) + 1) : 1;
            $this->noBerita = $today . str_pad($seq, 4, '0', STR_PAD_LEFT);
        }
        $this->createdAt = date('Y-m-d H:i:s');
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    public function beforeValidationOnUpdate()
    {

        $this->updatedAt = date('Y-m-d H:i:s');
    }
}
