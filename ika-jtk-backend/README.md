# IKA JTK Backend (PHP Phalcon)

Ini adalah *backend* utama untuk sistem informasi Ikatan Keluarga Alumni Jurusan Teknik Komputer dan Informatika (IKA JTK) Politeknik Negeri Bandung.

*Backend* ini dulunya menggunakan Node.js (Express & Prisma), tetapi sekarang telah **ditulis ulang sepenuhnya menggunakan PHP Phalcon** untuk performa yang lebih ringan dan cepat.

---

## 🛠️ Teknologi yang Digunakan
- **Framework:** PHP Phalcon 5 (Micro Application)
- **Database:** PostgreSQL (melalui PDO)
- **Autentikasi:** JSON Web Token (JWT) dengan library `firebase/php-jwt`
- **Email / OTP:** PHPMailer (terhubung melalui protokol SMTP Gmail)
- **Manajemen Dependensi:** Composer

---

## 🚀 Persiapan & Instalasi

### 1. Persyaratan Sistem
Pastikan perangkat Anda sudah terinstal perangkat lunak berikut:
- **PHP** (Versi 8.0 ke atas).
- **Ekstensi PHP:**
  - `ext-phalcon` (Wajib untuk framework)
  - `ext-pdo_pgsql` (Wajib untuk koneksi ke PostgreSQL)
  - `ext-curl`
- **Composer** (Atau bisa memakai `composer.phar` yang sudah disertakan).
- **PostgreSQL** Server.

*(Jika Anda pengguna Windows, kami sangat menyarankan untuk menggunakan **Laragon** karena mempermudah pengaturan PHP dan ekstensi PostgreSQL).*

### 2. Mengunduh Pustaka (Dependencies)
Masuk ke direktori ini melalui terminal, lalu jalankan perintah berikut untuk mengunduh pustaka JWT, PHPMailer, dan Dotenv:

```bash
php composer.phar install
# atau jika composer Anda sudah terdaftar di sistem:
composer install
```

### 3. Mengatur Konfigurasi (.env)
Salin berkas `.env.example` menjadi `.env` (atau buat file `.env` baru jika tidak ada) dan isikan pengaturan berikut sesuai dengan environment Anda. Jangan pernah meng-commit file `.env` yang berisi rahasia asli ke dalam Git!

```bash
cp .env.example .env
```

```env
# Konfigurasi Database (Ganti username dan password Anda)
DATABASE_URL="postgresql://postgres:password@localhost:5432/ika_jtk"

# Konfigurasi JWT (Ganti dengan kata sandi rahasia yang acak)
JWT_SECRET="ikajtk_secret_jwt_key_2026_super_secure"

# Konfigurasi Pengiriman Email OTP (Gunakan akun Google dan App Passwords)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="email.anda@gmail.com"
SMTP_PASS="password_aplikasi_gmail_anda"
SMTP_FROM="Alumni IKA JTK <email.anda@gmail.com>"
```

---

## 🗄️ Database & Migrasi (Phinx)

Skema database dikelola dengan **[Phinx](https://phinx.org)** — migrasi terversi yang mendukung *rollback* dan *seeding*. Konfigurasinya ada di `phinx.php` (membaca `DATABASE_URL` dari `.env`, satu sumber dengan `app/config/services.php`).

Pastikan PostgreSQL sudah berjalan (mis. lewat `docker compose up -d`), lalu:

```bash
# Membuat semua tabel + akun admin default sekaligus
composer db:setup

# Atau jalankan terpisah:
composer migrate          # menjalankan semua migrasi yang belum dijalankan
composer seed             # mengisi akun Super Admin default

composer migrate:status   # melihat status migrasi
composer migrate:rollback # membatalkan migrasi terakhir
```

Akun admin default hasil seed: **`admin@ikajtk.id`** / **`admin123`**.

Untuk menambah perubahan skema baru:

```bash
composer migrate:create NamaMigrasiBaru   # buat file migrasi di db/migrations/
# isi method up()/down(), lalu:
composer migrate
```

> Skrip migrasi manual lama (`create_tables.php`, `migrate_*.php`, dst.) sudah **digantikan** oleh Phinx dan dihapus.

---

## 🏃‍♂️ Menjalankan Server

Karena Phalcon bersifat sangat ringan, Anda tidak perlu *web server* berat seperti Apache/Nginx untuk fase pengembangan (development). Cukup gunakan *built-in server* milik PHP.

Pastikan posisi terminal Anda berada di dalam folder `ika-jtk-backend` ini, lalu jalankan perintah:

```bash
php -S localhost:5000 -t public
```

Server Anda akan menyala di `http://localhost:5000`.

---

## 📖 Dokumentasi API (Swagger)

Dokumentasi seluruh endpoint tersedia dalam format **OpenAPI 3** dan dapat
dibuka lewat **Swagger UI** di browser:

```
http://localhost:5000/docs
```

- Spesifikasi mentah: `http://localhost:5000/openapi.yaml`
  (file: [`public/openapi.yaml`](public/openapi.yaml)).
- Untuk mencoba endpoint terproteksi, klik **Authorize** di Swagger UI lalu
  masukkan token JWT (hasil dari `/api/auth/login` atau `/api/admin/auth/login`).

> Saat menambah/mengubah endpoint, perbarui juga `public/openapi.yaml`
> agar dokumentasi tetap sinkron.

---

## 📂 Struktur Direktori

Berikut adalah penjelasan mengenai struktur utama dari *backend* Phalcon ini:

- `app/config/`
  - `router.php`: Mengatur rute URL API (seperti `/api/auth/login`).
  - `services.php`: Menyimpan fungsi-fungsi global yang bisa digunakan di seluruh aplikasi (seperti koneksi *Database* dan pembacaan variabel konfigurasi).
- `app/controllers/`: Tempat berkumpulnya logika utama (seperti *login*, registrasi, mengambil daftar kandidat).
- `app/middleware/`: Penyaring *request* masuk. Di sinilah token JWT divalidasi sebelum diizinkan mengakses fungsi internal.
- `app/models/`: Penghubung (representasi) tabel-tabel di *database* PostgreSQL Anda.
- `db/`
  - `migrations/`: Berkas migrasi Phinx (definisi skema database, terversi).
  - `seeds/`: Berkas seeder Phinx (data awal, mis. akun admin default).
- `phinx.php`: Konfigurasi Phinx (koneksi DB dibaca dari `DATABASE_URL`).
- `public/`
  - `index.php`: Gerbang utama aplikasi Anda. Setiap *request* akan masuk dari sini terlebih dahulu.
  - `.htaccess`: Konfigurasi *rewrite* URL jika Anda menggunakan Apache di *server production*.
- `uploads/`: Direktori tempat foto (avatar) dan dokumen pendukung alumni akan disimpan secara otomatis.
