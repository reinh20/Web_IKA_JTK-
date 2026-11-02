<?php

namespace App\Cli;

/**
 * Prune AuditLog rows older than the configured retention window.
 *
 * Usage (from Phalcon CLI):
 *   php cli.php prune-audit-logs
 *
 * Or via cron (harian jam 03:00):
 *   0 3 * * * cd /path/to/ika-jtk-backend && php cli.php prune-audit-logs >> logs/audit-prune.log 2>&1
 *
 * Retention default: 180 hari (6 bulan). Override lewat env AUDIT_LOG_RETENTION_DAYS.
 */
class PruneAuditLogsTask
{
    public static function run(\Phalcon\Di\DiInterface $di): int
    {
        $days = (int) ($_ENV['AUDIT_LOG_RETENTION_DAYS'] ?? 180);
        if ($days < 1) $days = 180;

        $db = $di->getShared('db');
        $sql = 'DELETE FROM "AuditLog" WHERE "createdAt" < NOW() - INTERVAL \'' . $days . ' days\'';

        $before = (int) $db->fetchColumn('SELECT COUNT(*) FROM "AuditLog"');
        $db->execute($sql);
        $after  = (int) $db->fetchColumn('SELECT COUNT(*) FROM "AuditLog"');

        $deleted = $before - $after;
        echo sprintf(
            "[%s] Prune AuditLog selesai. Retention: %d hari. Terhapus: %d row (sebelum: %d, sesudah: %d).\n",
            date('Y-m-d H:i:s'), $days, $deleted, $before, $after
        );
        return $deleted;
    }
}
