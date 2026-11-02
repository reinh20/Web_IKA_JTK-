<?php

namespace App\Models;

use Phalcon\Mvc\Model;

use App\Traits\LogsChanges;

class Election extends Model
{
    use LogsChanges;

    public $id;
    public $judul;
    public $deskripsi;
    public $periodeStart;
    public $periodeEnd;
    public $kandidatStart;
    public $kandidatEnd;
    public $pengumumanDate;
    public $pelantikanDate;
    public $status = 'Draft';
    public $hideStatistik = 0;
    public $createdAt;
    public $updatedAt;
    public $deletedAt;

    protected function auditEntityType(): string
    {
        return 'Pemilu';
    }

    public function initialize()
    {
        $this->keepSnapshots(true);
        $this->setSource("Election");
        $this->hasMany('id', Candidate::class, 'electionId', ['alias' => 'Candidates']);
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

    public static function checkAndCompleteExpiredElections()
    {
        try {
            $now = date('Y-m-d H:i:s');
            $activeElections = self::find([
                'conditions' => 'deletedAt IS NULL AND status IN ({status:array}) AND periodeEnd <= :now:',
                'bind' => [
                    'status' => ['Active', 'Ongoing', 'active', 'ongoing', 'Sedang Berlangsung'],
                    'now' => $now
                ]
            ]);

            foreach ($activeElections as $e) {
                $e->status = 'Completed';
                $e->save();
            }
        } catch (\Throwable $ex) {
            // Ignore if error occurs
        }
    }
}
