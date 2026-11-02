<?php

use Phalcon\Db\Adapter\Pdo\Postgresql;

$di->setShared('db', function () {
    // Parsing DATABASE_URL dari .env jika ada (format prisma)
    // misal: postgresql://username:password@localhost:5432/ika_jtk?schema=public
    $dbUrl = $_ENV['DATABASE_URL'] ?? 'postgresql://postgres:password@localhost:5432/ika_jtk';
    $parsedUrl = parse_url($dbUrl);

    $host = $parsedUrl['host'] ?? 'localhost';
    $port = $parsedUrl['port'] ?? 5432;
    $username = $parsedUrl['user'] ?? 'postgres';
    $password = $parsedUrl['pass'] ?? '';
    $dbname = ltrim($parsedUrl['path'], '/');

    return new Postgresql([
        'host'     => $host,
        'username' => $username,
        'password' => $password,
        'dbname'   => $dbname,
        'port'     => $port,
    ]);
});

$di->setShared('config', function () {
    return [
        'jwt_secret' => $_ENV['JWT_SECRET'] ?? 'supersecretkey_change_me',
        'resend_api_key' => $_ENV['RESEND_API_KEY'] ?? '',
        'smtp_host' => $_ENV['SMTP_HOST'] ?? 'smtp.gmail.com',
        'smtp_port' => $_ENV['SMTP_PORT'] ?? 587,
        'smtp_user' => $_ENV['SMTP_USER'] ?? '',
        'smtp_pass' => $_ENV['SMTP_PASS'] ?? '',
        'smtp_from' => $_ENV['SMTP_FROM'] ?? ''
    ];
});

$di->setShared('spaces', function () {
    return new \App\Services\SpacesStorageService([
        'bucket'     => $_ENV['DO_SPACES_BUCKET']     ?? 'ikajtk-dev',
        'region'     => $_ENV['DO_SPACES_REGION']     ?? 'sgp1',
        'endpoint'   => $_ENV['DO_SPACES_ENDPOINT']   ?? 'https://sgp1.digitaloceanspaces.com',
        'public_url' => $_ENV['DO_SPACES_PUBLIC_URL'] ?? 'https://ikajtk-dev.sgp1.digitaloceanspaces.com',
        'key'        => $_ENV['DO_SPACES_KEY']        ?? '',
        'secret'     => $_ENV['DO_SPACES_SECRET']     ?? '',
    ]);
});

$di->setShared('imageProcessor', function () {
    return new \App\Services\ImageProcessorService();
});

$di->setShared('auditLog', function () use ($di) {
    return new \App\Services\AuditLogService($di);
});
