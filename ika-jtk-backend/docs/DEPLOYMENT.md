# Panduan Deployment — IKA JTK Backend (Server Linux, Tanpa Docker)

Dokumen ini menjelaskan cara men-deploy backend Phalcon ke **server Linux**
dengan PostgreSQL dan PHP **terpasang langsung di mesin (native)** — tanpa Docker.

Asumsi distro: **Ubuntu/Debian** (perintah `apt`). Catatan untuk RHEL/CentOS
diberikan bila berbeda. Sesuaikan versi PHP (`8.3`) dan PostgreSQL (`16`) bila perlu.

---

## 1. Prasyarat Server

### a. PostgreSQL (native)

```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql      # jalan otomatis saat boot
```
> RHEL/CentOS: `sudo dnf install -y postgresql-server && sudo postgresql-setup --initdb`

Buat user & database sesuai `DATABASE_URL`:
```bash
sudo -u postgres psql <<'SQL'
CREATE USER ikajtk WITH PASSWORD 'password_kuat_anda';
CREATE DATABASE "ika-jtk" OWNER ikajtk;
GRANT ALL PRIVILEGES ON DATABASE "ika-jtk" TO ikajtk;
SQL
```
> **Penting:** Phinx **tidak** membuat database — hanya tabel di dalamnya.
> Database `ika-jtk` harus sudah ada sebelum migrasi dijalankan.

### b. PHP + ekstensi

Phinx butuh `pdo_pgsql` + `mbstring`. Aplikasi Phalcon butuh ekstensi
`phalcon` (+ `psr` sebagai prasyarat) dan `curl`.

```bash
# Repositori PHP (Ondřej) untuk versi 8.x terbaru
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update

sudo apt install -y \
  php8.3-cli \
  php8.3-pgsql \
  php8.3-mbstring \
  php8.3-curl \
  php8.3-xml \
  php8.3-fpm
```

**Ekstensi Phalcon** (tidak ada di apt standar — pasang via PECL):
```bash
sudo apt install -y php8.3-dev php-pear gcc make libpcre3-dev

sudo pecl install psr        # prasyarat Phalcon, harus lebih dulu
sudo pecl install phalcon

# Aktifkan (urutan penting: psr sebelum phalcon)
echo "extension=psr.so"     | sudo tee /etc/php/8.3/mods-available/psr.ini
echo "extension=phalcon.so" | sudo tee /etc/php/8.3/mods-available/phalcon.ini
sudo phpenmod psr phalcon
sudo systemctl restart php8.3-fpm
```

> Jika hanya ingin menjalankan migrasi (Phinx), `ext-phalcon` **tidak** wajib —
> cukup `pdo_pgsql` + `mbstring`. Tetapi aplikasinya tetap membutuhkannya,
> jadi sebaiknya dipasang sekalian.

### c. Composer

```bash
sudo apt install -y composer
# Alternatif: gunakan composer.phar yang sudah disertakan di repo
```

### d. Verifikasi prasyarat

```bash
php -v
php -m | grep -E "pdo_pgsql|mbstring|phalcon|psr|curl"   # semua harus muncul
psql --version
```

---

## 2. Deploy Aplikasi (Instalasi Pertama)

```bash
# 1. Ambil kode
git clone <repo-url> /var/www/ika-jtk-backend
cd /var/www/ika-jtk-backend

# 2. Install dependensi
composer install --optimize-autoloader
```

> ⚠️ **Jebakan penting:** Phinx terdaftar di `require-dev`. Bila Anda deploy
> dengan `composer install --no-dev` (lazim di production), maka
> `vendor/bin/phinx` **tidak akan terpasang** dan migrasi gagal.
> Lihat [Bagian 5](#5-catatan-phinx-di-require-dev) untuk solusinya.

```bash
# 3. Siapkan .env (TIDAK ikut git — di-gitignore, jadi buat manual di server)
nano .env
```
Isi `.env` minimal:
```env
DATABASE_URL="postgresql://ikajtk:password_kuat_anda@localhost:5432/ika-jtk?schema=public"
JWT_SECRET="ganti_dengan_secret_acak_yang_kuat"
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="email@gmail.com"
SMTP_PASS="app_password_gmail"
SMTP_FROM="Alumni IKA JTK <email@gmail.com>"
```
> Host = `localhost` karena PostgreSQL native di mesin yang sama
> (berbeda dengan Docker yang memakai nama service).

```bash
# 4. Pastikan database 'ika-jtk' SUDAH dibuat (Bagian 1a)

# 5. Jalankan migrasi (pilih environment production)
php vendor/bin/phinx migrate -c phinx.php -e production

# 6. Seed admin default — HANYA saat instalasi pertama
php vendor/bin/phinx seed:run -c phinx.php -e production

# 7. Set permission folder upload agar bisa ditulis web server
sudo chown -R www-data:www-data public/uploads
sudo chmod -R 775 public/uploads
```

Admin default hasil seed: **`admin@ikajtk.id`** / **`admin123`**
(segera ganti password setelah login pertama).

---

## 3. Menjalankan Aplikasi di Production

Jangan gunakan `php -S` (built-in server) untuk production. Pakai **Nginx + PHP-FPM**.

Contoh konfigurasi Nginx (`/etc/nginx/sites-available/ika-jtk`):
```nginx
server {
    listen 80;
    server_name api.ikajtk.id;
    root /var/www/ika-jtk-backend/public;
    index index.php;

    client_max_body_size 20M;   # untuk upload dokumen/avatar

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Lindungi file sensitif
    location ~ /\.(env|git) { deny all; }
}
```
Aktifkan & reload:
```bash
sudo ln -s /etc/nginx/sites-available/ika-jtk /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```
> Disarankan pasang HTTPS via Certbot (`sudo certbot --nginx`).

---

## 4. Workflow Update (Deploy Berikutnya)

Urutan aman — **migrasi dijalankan sebelum reload service** agar skema baru
siap saat kode baru mulai berjalan:

```bash
cd /var/www/ika-jtk-backend
git pull
composer install --no-dev --optimize-autoloader   # (jika Phinx sudah di require — lihat Bagian 5)
php vendor/bin/phinx migrate -c phinx.php -e production
sudo systemctl reload php8.3-fpm
```

> `phinx migrate` aman dijalankan berulang — Phinx melacak migrasi yang sudah
> dijalankan di tabel `phinxlog` dan tidak akan mengulang. **`seed:run` tidak
> dilacak**, jadi hanya dijalankan saat instalasi awal (seeder admin idempoten,
> tetapi seeder lain belum tentu).

---

## 5. Catatan: Phinx ada di `require`

Phinx (`robmorgan/phinx`) terdaftar di **`require`** (bukan `require-dev`),
sehingga **tetap terpasang** meskipun deploy memakai `composer install --no-dev`.
`vendor/bin/phinx` akan selalu tersedia di server tanpa langkah tambahan.

> Bila `vendor/bin/phinx: Could not open input file` tetap muncul, berarti
> `composer install` belum berhasil membuat `vendor/` (sering karena masalah
> permission folder). Jalankan ulang `composer install --optimize-autoloader`
> dengan user yang memiliki izin tulis pada direktori project.

---

## 6. Troubleshooting

| Gejala | Penyebab & Solusi |
|--------|-------------------|
| `password authentication failed` | Auth Postgres lokal default `peer`/`ident`. Edit `/etc/postgresql/16/main/pg_hba.conf`, pastikan baris `local`/`host 127.0.0.1/32` memakai `scram-sha-256` (atau `md5`), lalu `sudo systemctl reload postgresql`. |
| `vendor/bin/phinx: No such file` | Phinx tidak terpasang karena `--no-dev`. Lihat Bagian 5. |
| `could not find driver` | Ekstensi `php-pgsql` belum terpasang/aktif. `sudo apt install php8.3-pgsql && sudo systemctl restart php8.3-fpm`. |
| `Class 'Phalcon\...' not found` | Ekstensi `phalcon` belum aktif. Cek `php -m | grep phalcon`; pastikan `psr` aktif lebih dulu. |
| Migrasi error `database "ika-jtk" does not exist` | Database belum dibuat. Lihat Bagian 1a — Phinx tidak membuat database. |
| Upload gagal/permission denied | Folder `public/uploads` tidak writable oleh `www-data`. Lihat Bagian 2 langkah 7. |
| `phinx` jalan di DB salah | Environment salah. Selalu sertakan `-e production` di server. |

---

## 7. Ringkasan Perintah Penting

```bash
# Prasyarat
sudo apt install -y postgresql php8.3-{cli,pgsql,mbstring,curl,xml,fpm} composer
sudo pecl install psr phalcon

# Deploy awal
git clone <repo-url> /var/www/ika-jtk-backend && cd $_
composer install --optimize-autoloader
nano .env                                              # isi DATABASE_URL dll.
php vendor/bin/phinx migrate  -c phinx.php -e production
php vendor/bin/phinx seed:run -c phinx.php -e production

# Update
git pull && composer install --no-dev --optimize-autoloader
php vendor/bin/phinx migrate -c phinx.php -e production
sudo systemctl reload php8.3-fpm
```
