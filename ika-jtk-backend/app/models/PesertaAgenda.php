<?php

namespace App\Models;

use Phalcon\Mvc\Model;

class PesertaAgenda extends Model
{
    public $id;
    public $agendaId;
    public $alumniId;
    public $nama;
    public $email;
    public $createdAt;

    public function initialize()
    {
        $this->setSource("peserta_agenda");
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
