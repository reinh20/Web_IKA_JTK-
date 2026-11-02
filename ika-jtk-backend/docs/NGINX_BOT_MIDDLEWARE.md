# Panduan Integrasi Pre-rendering Middleware (Opsi B) untuk Social Share

Dokumen ini menjelaskan cara mengonfigurasi web server production (`ikajtk.org`) agar bot/crawler dari **WhatsApp, Facebook, Twitter/X, Telegram, dan LinkedIn** mendapatkan kartu *preview* (Open Graph + Twitter Cards) yang dinamis per item (Berita, Agenda, Loker, Kandidat Pemilu, Profil Alumni) menggunakan skrip `public/bot-meta.php`.

---

## 1. Untuk Web Server NGINX (`ikajtk.org`)

Jika aplikasi Flutter Web (`ika-jtk-portal`) disajikan via Nginx pada blok server domain utama (`https://ikajtk.org`), tambahkan *intercept location & user-agent check* sebelum me-render `index.html`:

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name ikajtk.org www.ikajtk.org;

    root /var/www/ika-jtk-portal/build/web;
    index index.html;

    # 1. Cek apakah request datang dari Social Media Scraper / Bot
    set $is_bot 0;
    if ($http_user_agent ~* "facebookexternalhit|WhatsApp|TelegramBot|Twitterbot|LinkedInBot|Discordbot|Slackbot") {
        set $is_bot 1;
    }

    # 2. Cek apakah request menuju rute dinamis yang perlu kartu meta khusus
    if ($request_uri ~* "^/(berita|agenda|loker|pemilu|member|alumni|candidate)/([a-zA-Z0-9_-]+)") {
        set $is_bot "${is_bot}A";
    }

    # 3. Jika Bot + Rute Dinamis (1A), arahkan secara internal/reverse-proxy ke bot-meta.php di backend
    if ($is_bot = "1A") {
        # Jika backend berada di server yang sama (misal port 5000 / PHP-FPM)
        rewrite ^/(.*)$ /api/bot-meta.php?url=/$1 last;
    }

    # Location untuk static files dan SPA fallback Flutter Web
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Location menuju Backend PHP
    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

> **Penjelasan Nginx**:
> - Ketika pengguna biasa (Chrome, Safari, HP Android/iOS) membuka `https://ikajtk.org/berita/123`, Nginx langsung mengirim `index.html` dan aplikasi Flutter Web berjalan dengan mulus.
> - Ketika WhatsApp atau Facebook memverifikasi tautan (`User-Agent: WhatsApp/...`), Nginx mengalihkan request secara internal ke `/api/bot-meta.php` pada backend Phalcon Anda. Script PHP ini memproses ID dari database dan langsung membalikkan tag `<meta property="og:image">` berserta `<meta property="og:title">` artikel ke dalam chat WA/FB!

---

## 2. Untuk Web Server APACHE (`.htaccess`)

Jika server hosting menggunakan Apache (misalnya Shared Hosting, cPanel, atau LiteSpeed), konfigurasi sudah **otomatis tertanam** di dalam file `public/.htaccess` pada direktori backend ini:

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On

    # Intercept Social Media Bot / Scraper (WhatsApp, Facebook, Twitter, Telegram, LinkedIn)
    RewriteCond %{HTTP_USER_AGENT} (facebookexternalhit|WhatsApp|TelegramBot|Twitterbot|LinkedInBot|Discordbot|Slackbot) [NC]
    RewriteCond %{REQUEST_URI} ^/(berita|agenda|loker|pemilu|member|alumni|candidate)/ [NC]
    RewriteRule ^(.*)$ bot-meta.php?url=/$1 [QSA,L]

    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php?_url=/$1 [QSA,L]
</IfModule>
```

---

## 3. Cara Pengujian (`curl` / Scraper Simulator)

Anda dapat menguji apakah *middleware* `bot-meta.php` bekerja dengan benar di terminal lokal atau server production menggunakan perintah `curl` dengan menyimulasikan *header* `User-Agent` WhatsApp:

```bash
curl -i -A "WhatsApp/2.23.20.0" http://localhost:5000/bot-meta.php?type=berita&id=CONTOH_ID
```

Atau jika sudah terhubung dengan Nginx/Apache:
```bash
curl -i -A "facebookexternalhit/1.1" https://ikajtk.org/berita/CONTOH_ID
```

Output yang benar akan menghasilkan HTML ringan (*fast load < 50ms*) berupa:
```html
<!DOCTYPE html>
<html lang="id">
<head>
  <meta property="og:title" content="Judul Artikel Spesifik | IKA JTK">
  <meta property="og:image" content="https://ikajtk.org/uploads/berita/banner-123.jpg">
  ...
```
