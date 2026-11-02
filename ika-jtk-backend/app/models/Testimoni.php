<?php

namespace App\Models;

use Phalcon\Mvc\Model;

use App\Traits\LogsChanges;

class Testimoni extends Model
{
    use LogsChanges;

    public $id;
    public $alumniId;
    public $alumniNama;
    public $alumniAngkatan;
    public $alumniAvatarUrl;
    public $isi;
    public $visibility = 'public';
    public $status = 'Pending';
    public $createdAt;
    public $reviewedAt;
    public $updatedAt;
    public $deletedAt;
    public $rejectReason;
    public $rejectCount = null;

    protected function auditEntityType(): string
    {
        return 'Testimoni';
    }

    public function initialize()
    {
        $this->keepSnapshots(true);
        $this->setSource("Testimoni");
        $this->belongsTo('alumniId', Alumni::class, 'id', ['alias' => 'Alumni']);
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
        $this->createdAt = date('Y-m-d H:i:s');
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    public function beforeValidationOnUpdate()
    {
        $this->reviewedAt = date('Y-m-d H:i:s');
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    public function afterFetch()
    {
        // Try to update from relation dynamically
        $alumni = $this->getRelated('Alumni');
        if ($alumni) {
            $this->alumniNama = $alumni->nama;
            $this->alumniAngkatan = $alumni->angkatan;
            $this->alumniAvatarUrl = $alumni->avatarUrl;
        }
    }
}
