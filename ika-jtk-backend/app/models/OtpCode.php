<?php

namespace App\Models;

use Phalcon\Mvc\Model;

class OtpCode extends Model
{
    public $id;
    public $email;
    public $code;
    public $purpose;
    public $isUsed = false;
    public $expiresAt;
    public $createdAt;
    public $deletedAt;

    public function initialize()
    {
        $this->setSource("OtpCodes");
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
    }
}
