<?php

namespace App\Models;

use Phalcon\Mvc\Model;
use App\Traits\TracksStorageFields;
use App\Traits\LogsChanges;

class Admin extends Model
{
    use TracksStorageFields;
    use LogsChanges;

    protected function auditEntityType(): string { return 'Admin'; }
    protected function auditIgnoredFields(): array { return ['password', 'updatedAt', 'tokenVersion']; }

    public $id;
    public $nama;
    public $email;
    public $username;
    public $password;
    public $role = 'Super Admin';
    public $avatarUrl;
    public $tokenVersion = 1;
    public $createdAt;
    public $updatedAt;
    public $deletedAt;

    public function initialize()
    {
        $this->setSource("Admin");
        $this->keepSnapshots(true);

        // Jembatan: Admin (role) -> AdminRole (name)
        $this->belongsTo(
            'role',
            \App\Models\AdminRole::class,
            'name'
        );
    }

    protected function trackedStorageFields(): array
    {
        return ['avatarUrl'];
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
            $this->id = sprintf(
                '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                mt_rand(0, 0xffff), mt_rand(0, 0xffff),
                mt_rand(0, 0xffff),
                mt_rand(0, 0x0fff) | 0x4000,
                mt_rand(0, 0x3fff) | 0x8000,
                mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
            );
        }
        $this->createdAt = date('Y-m-d H:i:s');
        $this->updatedAt = date('Y-m-d H:i:s');
        if (empty($this->tokenVersion)) {
            $this->tokenVersion = 1;
        }
    }

    public function beforeValidationOnUpdate()
    {
        $this->updatedAt = date('Y-m-d H:i:s');
    }
}
