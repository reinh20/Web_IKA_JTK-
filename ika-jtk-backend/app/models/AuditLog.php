<?php

namespace App\Models;

use Phalcon\Mvc\Model;

class AuditLog extends Model
{
    public $id;
    public $source;
    public $actorType;
    public $actorId;
    public $actorName;
    public $actorRole;
    public $action;
    public $entityType;
    public $entityId;
    public $description;
    public $changes;
    public $metadata;
    public $ipAddress;
    public $userAgent;
    public $createdAt;

    public function initialize()
    {
        $this->setSource('AuditLog');
    }

    public function beforeValidationOnCreate()
    {
        if (empty($this->id)) {
            $this->id = sprintf(
                '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                mt_rand(0, 0xffff), mt_rand(0, 0xffff),
                mt_rand(0, 0xffff),
                mt_rand(0, 0x0fff) | 0x4000,
                mt_rand(0, 0x3fff) | 0x8000,
                mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
            );
        }
        if (empty($this->createdAt)) {
            $this->createdAt = date('Y-m-d H:i:s');
        }
        if (is_array($this->changes))  $this->changes  = json_encode($this->changes, JSON_UNESCAPED_UNICODE);
        if (is_array($this->metadata)) $this->metadata = json_encode($this->metadata, JSON_UNESCAPED_UNICODE);
    }

    public function beforeUpdate()
    {
        return false;
    }

    public function beforeDelete()
    {
        return false;
    }

    public function afterFetch()
    {
        if (is_string($this->changes)) {
            $decoded = json_decode($this->changes, true);
            if ($decoded !== null) $this->changes = $decoded;
        }
        if (is_string($this->metadata)) {
            $decoded = json_decode($this->metadata, true);
            if ($decoded !== null) $this->metadata = $decoded;
        }
    }
}
