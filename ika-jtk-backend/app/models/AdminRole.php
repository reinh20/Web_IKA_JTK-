<?php

namespace App\Models;

use Phalcon\Mvc\Model;
use App\Traits\LogsChanges;

class AdminRole extends Model
{
    use LogsChanges;

    public $id;
    public $name;
    public $permissions;
    public $isSystem;
    public $description;
    public $createdAt;
    public $updatedAt;
    public $deletedAt;

    protected function auditEntityType(): string { return 'AdminRole'; }
    protected function auditEntityId(): string { return (string) ($this->name ?? ''); }

    public function initialize()
    {
        $this->setSource("AdminRole");
        $this->keepSnapshots(true);

        // Jembatan balik: AdminRole (name) <- Admin (role)
        $this->hasMany(
            'name',
            \App\Models\Admin::class,
            'role'
        );
    }

    public function beforeValidationOnCreate()
    {
        // ID adalah string UUID/hex yang di-generate di level model,
        // konsisten dengan seluruh model lain (lihat Admin, AlumniVerification).
        if (!$this->id) {
            $this->id = bin2hex(random_bytes(16));
        }
        $this->createdAt = date('Y-m-d H:i:s');
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    public function beforeSave()
    {
        if (is_array($this->permissions)) {
            $this->permissions = json_encode($this->permissions);
        }
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    public function afterFetch()
    {
        if (is_string($this->permissions)) {
            $perms = json_decode($this->permissions, true) ?: [];
            
            // Auto-migrate legacy permissions (e.g. 'alumni') to granular ('alumni_view', 'alumni_edit')
            $granularPerms = [];
            foreach ($perms as $p) {
                if (strpos($p, '_') === false) {
                    $granularPerms[] = $p . '_view';
                    $granularPerms[] = $p . '_edit';
                } else {
                    $granularPerms[] = $p;
                }
            }
            
            $this->permissions = array_values(array_unique($granularPerms));
        }
    }
}
