<?php

namespace App\Traits;

use Phalcon\Di\Di;

/**
 * Auto-record CRUD activity to the AuditLog via Phalcon model events.
 *
 * Requirements:
 * - The model must call `$this->keepSnapshots(true);` in initialize().
 * - The consuming class must implement `auditEntityType()` returning e.g. 'Alumni'.
 *
 * Behaviour:
 * - afterCreate: log action=create with `changes.after` = filtered snapshot.
 * - afterUpdate:
 *     * If `deletedAt` transitioned from null to a value, log action=delete.
 *     * If `deletedAt` transitioned from a value to null, log action=restore.
 *     * Otherwise log action=update with only changed fields (minus ignored).
 */
trait LogsChanges
{
    abstract protected function auditEntityType(): string;

    protected function auditEntityId(): string
    {
        return (string) ($this->id ?? '');
    }

    protected function auditIgnoredFields(): array
    {
        return ['password', 'updatedAt', 'tokenVersion'];
    }

    private function auditFilter(array $data): array
    {
        $ignored = $this->auditIgnoredFields();
        foreach ($ignored as $f) unset($data[$f]);
        return $data;
    }

    private function auditService()
    {
        try {
            $di = Di::getDefault();
            if ($di && $di->has('auditLog')) return $di->getShared('auditLog');
        } catch (\Throwable $e) {}
        return null;
    }

    public function afterCreate()
    {
        $svc = $this->auditService();
        if (!$svc) return;

        if (method_exists($svc, 'shouldSkip') && $svc->shouldSkip($this->auditEntityType(), $this->auditEntityId())) {
            return;
        }

        $svc->log([
            'action'     => 'create',
            'entityType' => $this->auditEntityType(),
            'entityId'   => $this->auditEntityId(),
            'changes'    => [
                'before' => null,
                'after'  => $this->auditFilter($this->toArray()),
            ],
        ]);
    }

    public function afterUpdate()
    {
        $svc = $this->auditService();
        if (!$svc) return;

        if (method_exists($svc, 'shouldSkip') && $svc->shouldSkip($this->auditEntityType(), $this->auditEntityId())) {
            return;
        }

        // After save, getChangedFields() returns empty (snapshot refreshed).
        // Phalcon exposes getUpdatedFields() which retains the list of fields
        // that were actually written in the current save operation.
        if (method_exists($this, 'getUpdatedFields')) {
            $changed = $this->getUpdatedFields();
        } else {
            $changed = method_exists($this, 'getChangedFields') ? $this->getChangedFields() : [];
        }
        if (empty($changed)) return;

        $old = method_exists($this, 'getOldSnapshotData') ? ($this->getOldSnapshotData() ?: []) : [];

        // Soft delete detection: deletedAt null -> value
        if (in_array('deletedAt', $changed, true)) {
            $oldDeleted = $old['deletedAt'] ?? null;
            $newDeleted = $this->readAttribute('deletedAt');
            if (empty($oldDeleted) && !empty($newDeleted)) {
                $svc->log([
                    'action'     => 'delete',
                    'entityType' => $this->auditEntityType(),
                    'entityId'   => $this->auditEntityId(),
                    'changes'    => null,
                ]);
                return;
            }
            if (!empty($oldDeleted) && empty($newDeleted)) {
                $svc->log([
                    'action'     => 'restore',
                    'entityType' => $this->auditEntityType(),
                    'entityId'   => $this->auditEntityId(),
                    'changes'    => null,
                ]);
                return;
            }
        }

        $ignored = $this->auditIgnoredFields();
        $before  = [];
        $after   = [];
        foreach ($changed as $field) {
            if (in_array($field, $ignored, true)) continue;
            $before[$field] = $old[$field] ?? null;
            $after[$field]  = $this->readAttribute($field);
        }
        if (empty($before) && empty($after)) return;

        $svc->log([
            'action'     => 'update',
            'entityType' => $this->auditEntityType(),
            'entityId'   => $this->auditEntityId(),
            'changes'    => ['before' => $before, 'after' => $after],
        ]);
    }
}
