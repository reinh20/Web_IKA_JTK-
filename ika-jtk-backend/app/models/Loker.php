<?php

namespace App\Models;

use Phalcon\Mvc\Model;
use App\Traits\TracksStorageFields;
use App\Traits\LogsChanges;

class Loker extends Model
{
    use TracksStorageFields;
    use LogsChanges;

    protected function auditEntityType(): string { return 'Loker'; }

    public $id;
    public $noLoker;
    public $posisi;
    public $namaPerusahaan;
    public $websitePerusahaan;
    public $logoUrl;
    public $logoThumbnailUrl;
    public $jenisPekerjaan;
    public $tipeLokasi;
    public $kota;
    public $deskripsi;
    public $tags;
    public $skemaPelamaran = 'internal';
    public $linkExternal;
    public $formLamaran = '[]';
    public $pelamar = '[]';
    public $authorId;
    public $authorNama;
    public $authorRole;
    public $authorAvatarUrl;
    public $status = 'Draft';
    public $createdAt;
    public $updatedAt;
    public $deletedAt;
    public $publishedAt;

    public function initialize()
    {
        $this->setSource("Loker");
        $this->keepSnapshots(true);
    }

    // authorAvatarUrl adalah snapshot dari Alumni.avatarUrl — tidak owned, jangan track.
    protected function trackedStorageFields(): array
    {
        return ['logoUrl', 'logoThumbnailUrl'];
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
        if (empty($this->noLoker)) {
            $today = date('Ymd');
            $last = self::findFirst([
                'conditions' => 'noLoker LIKE ?0',
                'bind' => ["$today%"],
                'order' => 'noLoker DESC'
            ]);
            $seq = $last ? ((int)substr($last->noLoker, -4) + 1) : 1;
            $this->noLoker = $today . str_pad($seq, 4, '0', STR_PAD_LEFT);
        }
        $this->createdAt = date('Y-m-d H:i:s');
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    public function beforeValidationOnUpdate()
    {

        $this->updatedAt = date('Y-m-d H:i:s');
    }
}
