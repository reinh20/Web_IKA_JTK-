<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddAuditColumns extends AbstractMigration
{
    public function change(): void
    {
        // --- Admin ---
        $admin = $this->table('Admin');
        if (!$admin->hasColumn('updatedAt')) {
            $admin->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
                  ->update();
        }

        // --- PendingRegistration ---
        if ($this->hasTable('PendingRegistration')) {
            $pending = $this->table('PendingRegistration');
            if (!$pending->hasColumn('updatedAt')) {
                $pending->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
                        ->update();
            }
        }

        // --- Alumni_Verification ---
        $alumniVerif = $this->table('Alumni_Verification');
        if (!$alumniVerif->hasColumn('updatedAt')) {
            $alumniVerif->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
                        ->update();
        }

        // --- Testimoni: rename submittedAt -> createdAt, add updatedAt ---
        $testimoni = $this->table('Testimoni');
        if ($testimoni->hasColumn('submittedAt') && !$testimoni->hasColumn('createdAt')) {
            $testimoni->renameColumn('submittedAt', 'createdAt')->update();
        }
        if (!$testimoni->hasColumn('updatedAt')) {
            $testimoni->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
                      ->update();
        }

        // --- Candidate ---
        $candidate = $this->table('Candidate');
        $needsUpdate = false;
        if (!$candidate->hasColumn('createdAt')) {
            $candidate->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true]);
            $needsUpdate = true;
        }
        if (!$candidate->hasColumn('updatedAt')) {
            $candidate->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true]);
            $needsUpdate = true;
        }
        if ($needsUpdate) {
            $candidate->update();
        }

        // --- VoteRecord ---
        $voteRecord = $this->table('VoteRecord');
        if (!$voteRecord->hasColumn('updatedAt')) {
            $voteRecord->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
                       ->update();
        }

        // --- AdminRole ---
        $adminRole = $this->table('AdminRole', ['id' => false, 'primary_key' => 'name']);
        if (!$adminRole->hasColumn('createdAt')) {
            $adminRole->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
                      ->update();
        }
        if (!$adminRole->hasColumn('updatedAt')) {
            $adminRole->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
                      ->update();
        }
    }
}
