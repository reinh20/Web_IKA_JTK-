<?php

/**
 * Konfigurasi Phinx.
 *
 * Membaca DATABASE_URL dari .env (format Prisma/Postgres URL) agar
 * satu sumber konfigurasi dengan app/config/services.php.
 * Contoh: postgresql://user:pass@localhost:5432/ika_jtk?schema=public
 */

require __DIR__ . '/vendor/autoload.php';

if (file_exists(__DIR__ . '/.env')) {
    $dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
    $dotenv->load();
}

$dbUrl = $_ENV['DATABASE_URL'] ?? 'postgresql://postgres:password@localhost:5432/ika_jtk';
$parsed = parse_url($dbUrl);

$dbConfig = [
    'adapter' => 'pgsql',
    'host'    => $parsed['host'] ?? 'localhost',
    'name'    => ltrim($parsed['path'] ?? '/ika_jtk', '/'),
    'user'    => $parsed['user'] ?? 'postgres',
    'pass'    => $parsed['pass'] ?? '',
    'port'    => $parsed['port'] ?? 5432,
    'charset' => 'utf8',
];

return [
    'paths' => [
        'migrations' => __DIR__ . '/db/migrations',
        'seeds'      => __DIR__ . '/db/seeds',
    ],
    'environments' => [
        'default_migration_table' => 'phinxlog',
        'default_environment'     => 'development',
        'development'             => $dbConfig,
        'production'              => $dbConfig,
    ],
    'version_order' => 'creation',
];
