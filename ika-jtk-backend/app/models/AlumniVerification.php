<?php

namespace App\Models;

use Phalcon\Mvc\Model;

class AlumniVerification extends Model
{
    public $id;
    public $alumniId;
    public $adminId;
    public $status;
    public $reason;
    public $createdAt;
    public $deletedAt;

    public function initialize()
    {
        $this->setSource("Alumni_Verification");
    }

    public function beforeValidationOnCreate()
    {
        if (!$this->id) {
            $this->id = bin2hex(random_bytes(16));
        }
        if (!$this->createdAt) {
            $this->createdAt = date('Y-m-d H:i:s');
        }
    }
}
