<?php

/**
 * Backfill kolom noAlumni untuk semua alumni existing.
 *
 * Formula: TIF{yy}{6-digit}, di mana yy = tahun createdAt, dan 6-digit = COUNT alumni
 * belum-soft-deleted dengan createdAt <= alumni.createdAt. Formula ini match dengan
 * logic on-the-fly yang sebelumnya dipakai — jadi nomor yang alumni lihat di UI tidak
 * berubah setelah backfill.
 *
 * Cara pakai:
 *   php bin/backfill_no_alumni.php            # eksekusi real
 *   php bin/backfill_no_alumni.php --dry-run  # print kandidat + nomor, tidak update DB
 *
 * Idempotent — alumni yang sudah punya noAlumni akan di-skip.
 */

use Phalcon\Di\FactoryDefault;
use Phalcon\Di\Di;
use Dotenv\Dotenv;

define('BASE_PATH', dirname(__DIR__));
define('APP_PATH', BASE_PATH . '/app');

require BASE_PATH . '/vendor/autoload.php';

if (file_exists(BASE_PATH . '/.env')) {
    Dotenv::createImmutable(BASE_PATH)->load();
}

$di = new FactoryDefault();
include APP_PATH . '/config/services.php';
Di::setDefault($di);

$dryRun = in_array('--dry-run', $argv, true);
if ($dryRun) {
    echo "== DRY RUN mode: tidak update DB ==\n";
}

$db = $di->getShared('db');

echo "\n[Alumni] Cari kandidat backfill...\n";
$rows = $db->fetchAll(
    'SELECT "id", "nama", "createdAt" FROM "Alumni" '
    . 'WHERE "deletedAt" IS NULL AND "noAlumni" IS NULL '
    . 'ORDER BY "createdAt" ASC'
);
echo "    -> " . count($rows) . " kandidat.\n\n";

$totalOk = 0;
$totalSkip = 0;
$totalFail = 0;

foreach ($rows as $row) {
    $id = $row['id'];
    $nama = mb_strimwidth((string) ($row['nama'] ?? ''), 0, 40, '…');
    $createdAt = (string) $row['createdAt'];

    $countRow = $db->fetchOne(
        'SELECT COUNT(*) AS c FROM "Alumni" '
        . 'WHERE "deletedAt" IS NULL AND "createdAt" <= :ca',
        null,
        ['ca' => $createdAt]
    );
    $count = (int) ($countRow['c'] ?? 0);
    $yy = date('y', strtotime($createdAt));
    $noAlumni = 'TIF' . $yy . str_pad((string) $count, 6, '0', STR_PAD_LEFT);

    if ($dryRun) {
        echo "    DRY  {$id} {$nama} → {$noAlumni}\n";
        $totalOk++;
        continue;
    }

    try {
        $affected = $db->execute(
            'UPDATE "Alumni" SET "noAlumni" = :no WHERE "id" = :id AND "noAlumni" IS NULL',
            ['no' => $noAlumni, 'id' => $id]
        );
        if ($affected > 0) {
            echo "    OK   {$id} {$nama} → {$noAlumni}\n";
            $totalOk++;
        } else {
            echo "    SKIP {$id} {$nama} → sudah punya noAlumni\n";
            $totalSkip++;
        }
    } catch (\Throwable $e) {
        echo "    FAIL {$id} {$nama} → {$e->getMessage()}\n";
        $totalFail++;
    }
}

echo "\n== Ringkasan ==\n";
echo "  OK   : {$totalOk}\n";
echo "  SKIP : {$totalSkip}\n";
echo "  FAIL : {$totalFail}\n";

if ($dryRun) {
    echo "\n(dry-run — tidak ada perubahan disimpan)\n";
}
