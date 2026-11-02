<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddOrganizationToPortalConfig extends AbstractMigration
{
    public function up(): void
    {
        // Check if organization row already exists
        $row = $this->fetchRow('SELECT "key" FROM "PortalConfig" WHERE "key" = \'organization\'');
        if (empty($row)) {
            $orgData = [];
            $json = json_encode($orgData, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            $now = date('Y-m-d H:i:s');
            $this->execute(sprintf(
                'INSERT INTO "PortalConfig" ("key", "value", "createdAt", "updatedAt") VALUES (\'organization\', \'%s\', \'%s\', \'%s\')',
                str_replace('\'', '\'\'', $json),
                $now,
                $now
            ));
        }
    }

    public function down(): void
    {
        $this->execute('DELETE FROM "PortalConfig" WHERE "key" = \'organization\'');
    }
}
