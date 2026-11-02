<?php

namespace App\Models;

use Phalcon\Mvc\Model;

class AlumniGrafisRequest extends Model
{
    public $id;
    public $alumniId;
    public $kategori;
    public $grafisId;
    public $status;
    public $createdAt;
    public $updatedAt;
    public $deletedAt;

    public function initialize()
    {
        $this->setSource("AlumniGrafisRequests");

        $this->belongsTo(
            'alumniId',
            'App\Models\Alumni',
            'id',
            [
                'alias' => 'Alumni'
            ]
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
    }
}
