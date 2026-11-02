<?php

namespace App\Models;

use Phalcon\Mvc\Model;
use App\Traits\TracksStorageFields;
use App\Traits\LogsChanges;

class Candidate extends Model
{
    use TracksStorageFields;
    use LogsChanges;

    protected function auditEntityType(): string
    {
        return 'Kandidat Pemilu';
    }

    public $id;
    public $electionId;
    public $alumniId;
    public $nama;
    public $angkatan;
    public $fotoUrl;
    public $nomorUrut;
    public $visi;
    public $misi = '[]';
    public $pengalaman = '[]';
    public $programKerja = '[]';
    public $prestasi = '[]';
    public $tagline;
    public $voteCount = 0;
    public $createdAt;
    public $updatedAt;
    public $deletedAt;

    public function initialize()
    {
        $this->setSource("Candidate");
        $this->keepSnapshots(true);
        $this->belongsTo('electionId', Election::class, 'id', ['alias' => 'Election']);
    }

    protected function trackedStorageFields(): array
    {
        return ['fotoUrl'];
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
        $this->createdAt = date('Y-m-d H:i:s');
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    public function beforeValidationOnUpdate()
    {
        $this->updatedAt = date('Y-m-d H:i:s');
    }
}
