<?php

namespace App\Traits;

use Phalcon\Di\Di;

trait TracksStorageFields
{
    /**
     * Return array field storage yang OWNED oleh model ini
     * (bukan snapshot/denormalisasi dari model lain).
     */
    abstract protected function trackedStorageFields(): array;

    protected function cleanupOldStorageOnUpdate(): void
    {
        if (!method_exists($this, 'hasChanged') || !method_exists($this, 'getOldSnapshotData')) {
            return;
        }

        $old = $this->getOldSnapshotData() ?: [];
        $fieldsToDelete = [];

        foreach ($this->trackedStorageFields() as $field) {
            if (!$this->hasChanged($field)) {
                continue;
            }
            $oldValue = $old[$field] ?? null;
            if (!empty($oldValue)) {
                $fieldsToDelete[] = $oldValue;
            }
        }

        if (empty($fieldsToDelete)) {
            return;
        }

        try {
            if (!Di::getDefault()->has('spaces')) {
                return;
            }
            $spaces = Di::getDefault()->getShared('spaces');
            foreach ($fieldsToDelete as $val) {
                try {
                    $spaces->delete($val);
                } catch (\Throwable $e) {
                    error_log("Spaces delete error: " . $e->getMessage());
                }
            }
        } catch (\Throwable $e) {
            error_log("Spaces service init error: " . $e->getMessage());
        }
    }

    protected function cleanupAllStorageOnDelete(): void
    {
        $fieldsToDelete = [];
        foreach ($this->trackedStorageFields() as $field) {
            if (!empty($this->$field)) {
                $fieldsToDelete[] = $this->$field;
            }
        }

        if (empty($fieldsToDelete)) {
            return;
        }

        try {
            if (!Di::getDefault()->has('spaces')) {
                return;
            }
            $spaces = Di::getDefault()->getShared('spaces');
            foreach ($fieldsToDelete as $val) {
                try {
                    $spaces->delete($val);
                } catch (\Throwable $e) {
                    error_log("Spaces delete error: " . $e->getMessage());
                }
            }
        } catch (\Throwable $e) {
            error_log("Spaces service init error: " . $e->getMessage());
        }
    }
}
