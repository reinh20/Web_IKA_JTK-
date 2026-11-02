<?php

/**
 * Migrasi file lama dari public/uploads/ ke DigitalOcean Spaces.
 *
 * Cara pakai:
 *   1) Backup DB dulu: pg_dump ... > backup.sql
 *   2) php bin/migrate-uploads-to-spaces.php
 *
 * Script ini idempotent — bisa dijalankan berulang tanpa efek dobel:
 *   - Object di Spaces di-skip jika sudah ada (via objectExists).
 *   - UPDATE DB WHERE col = :old sudah tidak match setelah run pertama.
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

/** @var \App\Services\SpacesStorageService $spaces */
$spaces = $di->getShared('spaces');
$db     = $di->getShared('db');

$uploadDir = BASE_PATH . '/public/uploads';
if (!is_dir($uploadDir)) {
    echo "Folder {$uploadDir} tidak ditemukan. Tidak ada yang perlu dimigrasi.\n";
    exit(0);
}

// --- STEP 1: Kumpulkan set nama file yang tergolong ijazah (dari DB).
echo "[1/3] Mengumpulkan daftar file ijazah dari DB...\n";
$ijazahBasenames = [];
$rows = $db->fetchAll('SELECT "ijazahFile" FROM "Alumni" WHERE "ijazahFile" IS NOT NULL AND "ijazahFile" <> \'\'');
foreach ($rows as $r) {
    $val = $r['ijazahFile'] ?? '';
    if ($val !== '') {
        $ijazahBasenames[basename($val)] = true;
    }
}
echo "    -> " . count($ijazahBasenames) . " file ijazah teridentifikasi.\n";

// --- STEP 2: Iterasi folder uploads, upload ke Spaces, bangun mapping.
echo "[2/3] Mengunggah file ke Spaces...\n";

$mimeMap = [
    'jpg'  => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'png'  => 'image/png',
    'webp' => 'image/webp',
    'pdf'  => 'application/pdf',
];

$mapping = []; // old_relative_path (/uploads/xxx) => new_value (URL absolute atau key mentah)
$uploaded = 0;
$skipped  = 0;
$failed   = 0;

foreach (new DirectoryIterator($uploadDir) as $f) {
    if ($f->isDot() || !$f->isFile()) {
        continue;
    }
    $name = $f->getFilename();
    $ext  = strtolower(pathinfo($name, PATHINFO_EXTENSION)) ?: 'bin';
    $mime = $mimeMap[$ext] ?? 'application/octet-stream';

    if (isset($ijazahBasenames[$name])) {
        $prefix = 'ijazah';
        $acl    = 'private';
    } elseif (str_starts_with($name, 'avatar_')) {
        $prefix = 'avatar';
        $acl    = 'public-read';
    } else {
        $prefix = 'document';
        $acl    = 'public-read';
    }

    $key         = $prefix . '/' . $name;
    $oldRelative = '/uploads/' . $name;

    try {
        if ($spaces->objectExists($key)) {
            echo "    SKIP (exists): {$key}\n";
            $skipped++;
        } else {
            $body = file_get_contents($f->getPathname());
            if ($body === false) {
                echo "    FAIL (read): {$name}\n";
                $failed++;
                continue;
            }
            $spaces->upload($key, $body, $mime, $acl);
            echo "    OK: {$oldRelative} -> {$key} ({$acl})\n";
            $uploaded++;
        }
        $mapping[$oldRelative] = ($acl === 'private')
            ? $key
            : ($spaces->getPublicUrlBase() . '/' . $key);
    } catch (\Throwable $e) {
        echo "    FAIL: {$name} — " . $e->getMessage() . "\n";
        $failed++;
    }
}

echo "    -> uploaded={$uploaded}, skipped={$skipped}, failed={$failed}\n";

if (empty($mapping)) {
    echo "Tidak ada mapping untuk diaplikasikan ke DB. Selesai.\n";
    exit(0);
}

// --- STEP 3: Update kolom URL di DB, dalam satu transaksi.
echo "[3/3] Memperbarui kolom URL di DB...\n";

$targets = [
    ['Alumni',    'avatarUrl'],
    ['Alumni',    'ijazahFile'],
    ['Admin',     'avatarUrl'],
    ['Berita',    'bannerUrl'],
    ['Berita',    'authorAvatarUrl'],
    ['Agenda',    'bannerUrl'],
    ['Agenda',    'authorAvatarUrl'],
    ['Loker',     'logoUrl'],
    ['Loker',     'authorAvatarUrl'],
    ['Testimoni', 'alumniAvatarUrl'],
    ['Candidate', 'fotoUrl'],
];

$db->begin();
try {
    foreach ($targets as [$table, $col]) {
        $rowsUpdated = 0;
        foreach ($mapping as $old => $new) {
            $sql = 'UPDATE "' . $table . '" SET "' . $col . '" = :new WHERE "' . $col . '" = :old';
            $db->execute($sql, ['new' => $new, 'old' => $old]);
            $rowsUpdated += $db->affectedRows();
        }
        echo "    {$table}.{$col}: {$rowsUpdated} row(s) updated.\n";
    }
    $db->commit();
    echo "Transaksi DB berhasil di-commit.\n";
} catch (\Throwable $e) {
    $db->rollback();
    echo "GAGAL — transaksi di-rollback: " . $e->getMessage() . "\n";
    exit(1);
}

echo "Selesai. Total file diproses: " . count($mapping) . "\n";
