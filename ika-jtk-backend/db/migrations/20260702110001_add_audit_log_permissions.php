<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddAuditLogPermissions extends AbstractMigration
{
    public function change(): void
    {
        $adapter = $this->getAdapter();
        $rows    = $adapter->fetchAll('SELECT name, permissions FROM "AdminRole" WHERE name = \'Super Admin\'');

        foreach ($rows as $row) {
            $perms = [];
            if (!empty($row['permissions'])) {
                $decoded = json_decode((string) $row['permissions'], true);
                if (is_array($decoded)) $perms = $decoded;
            }
            if (!in_array('audit_log_view', $perms, true)) {
                $perms[] = 'audit_log_view';
                $this->execute(
                    'UPDATE "AdminRole" SET permissions = ' . $adapter->getConnection()->quote(json_encode(array_values($perms))) . ', "updatedAt" = CURRENT_TIMESTAMP WHERE name = ' . $adapter->getConnection()->quote($row['name'])
                );
            }
        }
    }
}
