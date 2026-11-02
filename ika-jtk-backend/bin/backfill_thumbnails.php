<?php

/**
 * Backfill bannerThumbnailUrl untuk Berita & Agenda yang existing.
 *
 * Cara pakai:
 *   php bin/backfill_thumbnails.php            # eksekusi real
 *   php bin/backfill_thumbnails.php --dry-run  # cuma print kandidat, tidak upload / update DB
 *
 * Script ini idempotent — record yang sudah punya bannerThumbnailUrl akan di-skip.
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
    echo "== DRY RUN mode: tidak upload ke Spaces, tidak update DB ==\n";
}

/** @var \App\Services\SpacesStorageService $spaces */
$spaces = $di->getShared('spaces');
/** @var \App\Services\ImageProcessorService $imageProcessor */
$imageProcessor = $di->getShared('imageProcessor');
$db = $di->getShared('db');

$publicUrlBase = $spaces->getPublicUrlBase();

$tables = [
    ['label' => 'Berita', 'table' => 'Berita'],
    ['label' => 'Agenda', 'table' => 'Agenda'],
];

$totalOk = 0;
$totalSkip = 0;
$totalFail = 0;

foreach ($tables as $t) {
    $label = $t['label'];
    $tbl   = $t['table'];
    echo "\n[{$label}] Cari kandidat...\n";

    $rows = $db->fetchAll(
        'SELECT "id", "judul", "bannerUrl" FROM "' . $tbl . '" ' .
        'WHERE "bannerUrl" IS NOT NULL AND "bannerUrl" <> \'\' ' .
        'AND ("bannerThumbnailUrl" IS NULL OR "bannerThumbnailUrl" = \'\') ' .
        'AND "deletedAt" IS NULL'
    );
    echo "    -> " . count($rows) . " kandidat.\n";

    foreach ($rows as $row) {
        $id    = $row['id'];
        $judul = mb_strimwidth((string) ($row['judul'] ?? ''), 0, 50, '…');
        $url   = (string) $row['bannerUrl'];

        // Extract ext dari URL (strip query string kalau ada).
        $path = parse_url($url, PHP_URL_PATH) ?: $url;
        $ext  = strtolower(pathinfo($path, PATHINFO_EXTENSION));
        if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp'], true)) {
            echo "    SKIP [{$label}] {$id} {$judul} → ext tidak didukung ({$ext})\n";
            $totalSkip++;
            continue;
        }

        // Download original.
        $body = @file_get_contents($url);
        if ($body === false || $body === '') {
            echo "    FAIL [{$label}] {$id} {$judul} → gagal download {$url}\n";
            $totalFail++;
            continue;
        }

        // Generate thumbnail.
        try {
            $thumb = $imageProcessor->generateThumbnail($body, $ext);
        } catch (\Throwable $e) {
            echo "    FAIL [{$label}] {$id} {$judul} → thumbnail error: " . $e->getMessage() . "\n";
            $totalFail++;
            continue;
        }

        // Bikin key thumbnail berdasar key original (kalau URL adalah Spaces URL).
        $baseName = pathinfo($path, PATHINFO_FILENAME);
        if (str_starts_with($url, $publicUrlBase . '/')) {
            $origKey  = substr($url, strlen($publicUrlBase) + 1);
            $dir      = dirname($origKey);
            $thumbKey = ($dir === '.' ? '' : $dir . '/') . $baseName . '_thumb.' . $thumb['ext'];
        } else {
            // URL luar (legacy) — taruh di document/ dengan nama uniqid.
            $thumbKey = 'document/backfill_' . uniqid() . '_thumb.' . $thumb['ext'];
        }

        if ($dryRun) {
            echo "    DRY  [{$label}] {$id} {$judul} → thumb key: {$thumbKey} (" . strlen($thumb['body']) . " bytes)\n";
            $totalOk++;
            continue;
        }

        try {
            $thumbUrl = $spaces->upload($thumbKey, $thumb['body'], $thumb['mime'], 'public-read');
        } catch (\Throwable $e) {
            echo "    FAIL [{$label}] {$id} {$judul} → upload error: " . $e->getMessage() . "\n";
            $totalFail++;
            continue;
        }

        // Update DB tanpa lewat model — hindari trait cleanup trigger.
        $db->execute(
            'UPDATE "' . $tbl . '" SET "bannerThumbnailUrl" = :thumb WHERE "id" = :id',
            ['thumb' => $thumbUrl, 'id' => $id]
        );
        echo "    OK   [{$label}] {$id} {$judul}\n";
        $totalOk++;
    }
}

echo "\n=== Summary ===\n";
echo "OK   : {$totalOk}\n";
echo "SKIP : {$totalSkip}\n";
echo "FAIL : {$totalFail}\n";
if ($dryRun) {
    echo "(dry-run — tidak ada perubahan yang di-commit)\n";
}
