<?php

namespace App\Models;

use Phalcon\Mvc\Model;

class VoteRecord extends Model
{
    public $id;
    public $alumniId;
    public $electionId;
    public $candidateId;
    public $createdAt;
    public $updatedAt;
    public $deletedAt;

    public function initialize()
    {
        $this->setSource("VoteRecord");
        $this->belongsTo('alumniId', Alumni::class, 'id', ['alias' => 'Alumni']);
        $this->belongsTo('electionId', Election::class, 'id', ['alias' => 'Election']);
        $this->belongsTo('candidateId', Candidate::class, 'id', ['alias' => 'Candidate']);
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
