<?php
/**
 * Pre-rendering / Social Share Middleware for IKA JTK Portal
 * 
 * Script ini dirancang untuk diakses oleh Crawler/Bot Social Media (WhatsApp, Facebook, Twitter/X, Telegram, LinkedIn)
 * ketika menyalin tautan (copy-paste link) dari halaman Berita, Agenda, Loker, Kandidat Pemilu, atau Profil Alumni.
 * 
 * Cara Kerja:
 * 1. Mengambil parameter `type` dan `id` dari query string atau URI path.
 * 2. Terhubung ke database PostgreSQL menggunakan `DATABASE_URL` dari `.env`.
 * 3. Menghasilkan tag HTML minimal yang berisi `<meta property="og:title">`, `<meta property="og:image">`, 
 *    dan Twitter Cards lengkap agar kartu tautan di dalam chat/story muncul dengan foto dan deskripsi yang akurat.
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;

// 1. Muat .env jika ada
if (file_exists(__DIR__ . '/../.env')) {
    $dotenv = Dotenv::createImmutable(__DIR__ . '/..');
    $dotenv->safeLoad();
}

// 2. Deteksi parameter `type` dan `id`
$type = $_GET['type'] ?? '';
$id = $_GET['id'] ?? '';

if (empty($type) || empty($id)) {
    $uri = $_GET['_url'] ?? $_GET['url'] ?? $_SERVER['REQUEST_URI'] ?? '';
    // Hapus tanda pagar (#) jika masih ada di string path sebelum regex
    $cleanUri = str_replace(['/#/', '/#', '#/'], '/', $uri);
    $path = parse_url($cleanUri, PHP_URL_PATH) ?: $cleanUri;
    if (preg_match('#/(berita|agenda|loker|pemilu|member|alumni|candidate)(?:/profile|/detail)?/([a-zA-Z0-9_-]+)#i', $path, $m)) {
        $type = strtolower($m[1]);
        $id = $m[2];
    }
}

// 3. Nilai Default Meta
$title = "Portal Alumni IKA JTK POLBAN";
$description = "Wadah resmi Ikatan Alumni Teknik Komputer dan Informatika Politeknik Negeri Bandung. Karir, Berita, Agenda, dan Direktori Alumni.";
$imageUrl = "https://ikajtk.org/icons/Icon-512.png";
$targetUrl = "https://ikajtk.org/" . ($type && $id ? "$type/$id" : "");
$ogType = "website";

// 4. Hubungkan ke Database dan Ambil Data Spesifik
try {
    $dbUrl = $_ENV['DATABASE_URL'] ?? 'postgresql://postgres:password@localhost:5432/ika_jtk';
    $parsedUrl = parse_url($dbUrl);

    $host = $parsedUrl['host'] ?? 'localhost';
    $port = $parsedUrl['port'] ?? 5432;
    $username = $parsedUrl['user'] ?? 'postgres';
    $password = $parsedUrl['pass'] ?? '';
    $dbname = ltrim($parsedUrl['path'] ?? 'ika_jtk', '/');

    $dsn = "pgsql:host={$host};port={$port};dbname={$dbname}";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);

    if ($type === 'berita' && !empty($id)) {
        $stmt = $pdo->prepare('SELECT "judul", "konten", "bannerUrl", "bannerThumbnailUrl" FROM "Berita" WHERE "id" = :id LIMIT 1');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();
        if ($row) {
            $title = $row['judul'] . " | IKA JTK";
            $cleanContent = trim(strip_tags($row['konten'] ?? ''));
            $description = mb_substr($cleanContent, 0, 160) . (mb_strlen($cleanContent) > 160 ? '...' : '');
            if (!empty($row['bannerUrl'])) {
                $imageUrl = $row['bannerUrl'];
            }
            $ogType = "article";
        }
    } elseif ($type === 'agenda' && !empty($id)) {
        $stmt = $pdo->prepare('SELECT "judul", "deskripsi", "bannerUrl" FROM "Agenda" WHERE "id" = :id LIMIT 1');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();
        if ($row) {
            $title = "Agenda: " . $row['judul'] . " | IKA JTK";
            $cleanContent = trim(strip_tags($row['deskripsi'] ?? ''));
            $description = mb_substr($cleanContent, 0, 160) . (mb_strlen($cleanContent) > 160 ? '...' : '');
            if (!empty($row['bannerUrl'])) {
                $imageUrl = $row['bannerUrl'];
            }
            $ogType = "article";
        }
    } elseif ($type === 'loker' && !empty($id)) {
        $stmt = $pdo->prepare('SELECT "posisi", "namaPerusahaan", "deskripsi", "logoUrl" FROM "Loker" WHERE "id" = :id LIMIT 1');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();
        if ($row) {
            $title = "Lowongan: " . $row['posisi'] . " di " . $row['namaPerusahaan'] . " | IKA JTK";
            $cleanContent = trim(strip_tags($row['deskripsi'] ?? ''));
            $description = mb_substr($cleanContent, 0, 160) . (mb_strlen($cleanContent) > 160 ? '...' : '');
            if (!empty($row['logoUrl'])) {
                $imageUrl = $row['logoUrl'];
            }
            $ogType = "article";
        }
    } elseif (($type === 'pemilu' || $type === 'candidate') && !empty($id)) {
        $stmt = $pdo->prepare('SELECT "nama", "nomorUrut", "visi", "fotoUrl" FROM "Candidate" WHERE "id" = :id LIMIT 1');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();
        if ($row) {
            $title = "Kandidat #" . $row['nomorUrut'] . ": " . $row['nama'] . " | Pemilu IKA JTK";
            $cleanContent = trim(strip_tags($row['visi'] ?? ''));
            $description = mb_substr($cleanContent, 0, 160) . (mb_strlen($cleanContent) > 160 ? '...' : '');
            if (!empty($row['fotoUrl'])) {
                $imageUrl = $row['fotoUrl'];
            }
            $ogType = "profile";
        }
    } elseif (($type === 'member' || $type === 'alumni') && !empty($id)) {
        $stmt = $pdo->prepare('SELECT "nama", "angkatan", "motto", "avatarUrl" FROM "Alumni" WHERE "id" = :id LIMIT 1');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();
        if ($row) {
            $title = "Profil Alumni: " . $row['nama'] . " (" . $row['angkatan'] . ") | IKA JTK";
            $cleanContent = trim(strip_tags($row['motto'] ?? 'Profil alumni IKA JTK POLBAN'));
            $description = mb_substr($cleanContent, 0, 160);
            if (!empty($row['avatarUrl'])) {
                $imageUrl = $row['avatarUrl'];
            }
            $ogType = "profile";
        }
    }
} catch (Exception $e) {
    // Jika koneksi DB gagal atau terjadi error, fallback ke meta default
}

// 5. Output HTML lengkap untuk Scraper & Bot
?>
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title><?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?></title>
  <meta name="description" content="<?= htmlspecialchars($description, ENT_QUOTES, 'UTF-8') ?>">

  <!-- Open Graph -->
  <meta property="og:type" content="<?= htmlspecialchars($ogType, ENT_QUOTES, 'UTF-8') ?>">
  <meta property="og:site_name" content="IKA JTK POLBAN">
  <meta property="og:title" content="<?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?>">
  <meta property="og:description" content="<?= htmlspecialchars($description, ENT_QUOTES, 'UTF-8') ?>">
  <meta property="og:image" content="<?= htmlspecialchars($imageUrl, ENT_QUOTES, 'UTF-8') ?>">
  <meta property="og:url" content="<?= htmlspecialchars($targetUrl, ENT_QUOTES, 'UTF-8') ?>">

  <!-- Twitter Cards -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="<?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?>">
  <meta name="twitter:description" content="<?= htmlspecialchars($description, ENT_QUOTES, 'UTF-8') ?>">
  <meta name="twitter:image" content="<?= htmlspecialchars($imageUrl, ENT_QUOTES, 'UTF-8') ?>">

  <!-- Canonical -->
  <link rel="canonical" href="<?= htmlspecialchars($targetUrl, ENT_QUOTES, 'UTF-8') ?>">

  <!-- Fallback Redirect untuk manusia jika secara tidak sengaja membuka URL bot-meta -->
  <script>
    if (window.location.pathname.indexOf('/bot-meta') !== -1) {
      window.location.replace("<?= htmlspecialchars($targetUrl, ENT_QUOTES, 'UTF-8') ?>");
    }
  </script>
</head>
<body>
  <h1><?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?></h1>
  <p><?= htmlspecialchars($description, ENT_QUOTES, 'UTF-8') ?></p>
  <img src="<?= htmlspecialchars($imageUrl, ENT_QUOTES, 'UTF-8') ?>" alt="Share Preview Image" style="max-width:100%;">
</body>
</html>
