<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddSoftDeleteToAllTables extends AbstractMigration
{
    public function up(): void
    {
        $tables = [
            'Admin', 'AdminRole', 'Agenda', 'Alumni', 'Alumni_Verification',
            'Berita', 'Candidate', 'Election', 'Loker', 'OtpCodes',
            'PendingRegistration', 'PortalConfig', 'Testimoni', 'VoteRecord'
        ];

        foreach ($tables as $table) {
            if (!$this->table($table)->hasColumn('deletedAt')) {
                $this->table($table)
                     ->addColumn('deletedAt', 'timestamp', ['null' => true, 'default' => null])
                     ->update();
            }
        }

        $this->execute('ALTER TABLE "Admin" DROP CONSTRAINT IF EXISTS "Admin_email_key"');
        $this->execute('ALTER TABLE "Admin" DROP CONSTRAINT IF EXISTS "Admin_username_key"');
        $this->execute('DROP INDEX IF EXISTS "Admin_email_key"');
        $this->execute('DROP INDEX IF EXISTS "Admin_username_key"');
        $this->execute('CREATE UNIQUE INDEX IF NOT EXISTS unique_admin_email ON "Admin"("email") WHERE "deletedAt" IS NULL');
        $this->execute('CREATE UNIQUE INDEX IF NOT EXISTS unique_admin_username ON "Admin"("username") WHERE "deletedAt" IS NULL');

        $this->execute('ALTER TABLE "Alumni" DROP CONSTRAINT IF EXISTS "Alumni_email_key"');
        $this->execute('ALTER TABLE "Alumni" DROP CONSTRAINT IF EXISTS "Alumni_username_key"');
        $this->execute('DROP INDEX IF EXISTS "Alumni_email_key"');
        $this->execute('DROP INDEX IF EXISTS "Alumni_username_key"');
        $this->execute('CREATE UNIQUE INDEX IF NOT EXISTS unique_alumni_email ON "Alumni"("email") WHERE "deletedAt" IS NULL');
        $this->execute('CREATE UNIQUE INDEX IF NOT EXISTS unique_alumni_username ON "Alumni"("username") WHERE "deletedAt" IS NULL');
    }

    public function down(): void
    {
        $this->execute('DROP INDEX IF EXISTS unique_admin_email');
        $this->execute('DROP INDEX IF EXISTS unique_admin_username');
        $this->execute('DROP INDEX IF EXISTS unique_alumni_email');
        $this->execute('DROP INDEX IF EXISTS unique_alumni_username');

        $tables = [
            'Admin', 'AdminRole', 'Agenda', 'Alumni', 'Alumni_Verification',
            'Berita', 'Candidate', 'Election', 'Loker', 'OtpCodes',
            'PendingRegistration', 'PortalConfig', 'Testimoni', 'VoteRecord'
        ];

        foreach ($tables as $table) {
            if ($this->table($table)->hasColumn('deletedAt')) {
                $this->table($table)
                     ->removeColumn('deletedAt')
                     ->update();
            }
        }
    }
}
