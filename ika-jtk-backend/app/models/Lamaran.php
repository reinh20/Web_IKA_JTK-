<?php

namespace App\Models;

use Phalcon\Mvc\Model;

class Lamaran extends Model
{
    public $id;
    public $lokerId;
    public $alumniId;
    public $jawaban = '{}';
    public $status = 'Sedang Direview';
    public $createdAt;
    public $updatedAt;
    public $deletedAt;

    public function initialize()
    {
        $this->setSource("Lamaran");

        $this->belongsTo(
            'lokerId',
            \App\Models\Loker::class,
            'id',
            ['alias' => 'loker']
        );

        $this->belongsTo(
            'alumniId',
            \App\Models\Alumni::class,
            'id',
            ['alias' => 'alumni']
        );
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
