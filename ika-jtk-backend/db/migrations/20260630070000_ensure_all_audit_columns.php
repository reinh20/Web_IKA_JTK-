<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class EnsureAllAuditColumns extends AbstractMigration
{
    public function change(): void
    {
        // 1. AdminRole
        $adminRole = $this->table('AdminRole', ['id' => false, 'primary_key' => 'name']);
        if (!$adminRole->hasColumn('createdAt')) {
            $adminRole->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true]);
        }
        if (!$adminRole->hasColumn('updatedAt')) {
            $adminRole->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true]);
        }
        $adminRole->update();

        // 2. Agenda (has createdat in lowercase, ensure updatedAt exists)
        $agenda = $this->table('Agenda');
        if (!$agenda->hasColumn('updatedAt') && !$agenda->hasColumn('updatedat')) {
            $agenda->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true]);
        }
        $agenda->update();

        // 3. Berita (has createdat in lowercase, ensure updatedAt exists)
        $berita = $this->table('Berita');
        if (!$berita->hasColumn('updatedAt') && !$berita->hasColumn('updatedat')) {
            $berita->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true]);
        }
        $berita->update();

        // 4. Loker (has createdat in lowercase, ensure updatedAt exists)
        $loker = $this->table('Loker');
        if (!$loker->hasColumn('updatedAt') && !$loker->hasColumn('updatedat')) {
            $loker->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true]);
        }
        $loker->update();

        // 5. OtpCodes
        $otp = $this->table('OtpCodes', ['id' => false, 'primary_key' => 'id']);
        if (!$otp->hasColumn('updatedAt')) {
            $otp->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true]);
        }
        $otp->update();

        // 6. PortalConfig
        $portalConfig = $this->table('PortalConfig', ['id' => false, 'primary_key' => 'key']);
        if (!$portalConfig->hasColumn('createdAt')) {
            $portalConfig->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true]);
        }
        $portalConfig->update();
    }
}
