<?php

/**
 * Workaround wrapper untuk `phinx migrate`.
 *
 * Bug Phinx 0.13 (dengan version_order=creation): `phinx migrate` tanpa
 * flag `-t` akan exit "All Done" 0.03s tanpa menjalankan migration apa pun.
 * Script ini otomatis cari version terbaru dari db/migrations/ lalu invoke
 * phinx dengan `-t <version>` explicit.
 *
 * Usage:
 *   php bin/phinx-migrate.php                 # env = development (default)
 *   php bin/phinx-migrate.php production
 */

$root = dirname(__DIR__);
$migrationsDir = $root . '/db/migrations';

$files = glob($migrationsDir . '/*.php') ?: [];
if (!$files) {
    fwrite(STDERR, "No migration files found in {$migrationsDir}\n");
    exit(1);
}

sort($files);
$latest = basename(end($files));

if (!preg_match('/^(\d{14})_/', $latest, $m)) {
    fwrite(STDERR, "Cannot parse version from filename: {$latest}\n");
    exit(1);
}
$targetVersion = $m[1];

$env = $argv[1] ?? 'development';
$phinxBin = $root . '/vendor/robmorgan/phinx/bin/phinx';
$configPath = $root . '/phinx.php';

$cmd = sprintf(
    '%s %s migrate -c %s -e %s -t %s',
    escapeshellarg(PHP_BINARY),
    escapeshellarg($phinxBin),
    escapeshellarg($configPath),
    escapeshellarg($env),
    escapeshellarg($targetVersion)
);

echo "Latest migration version: {$targetVersion}\n";
echo "> {$cmd}\n\n";

passthru($cmd, $exitCode);
exit($exitCode);
