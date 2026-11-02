# Workflow Pengembangan — IKA JTK Backend (PHP Phalcon 5)

Dokumen ini menjelaskan arsitektur dan alur kerja (workflow) backend IKA JTK
yang dibangun dengan **PHP Phalcon 5 (Micro Application)** + **PostgreSQL**.
Tujuannya: siapa pun yang baru masuk bisa memahami bagaimana request mengalir,
bagaimana menambah fitur, dan bagaimana mengelola database.

---

## 1. Tumpukan Teknologi (Tech Stack)

| Komponen | Teknologi |
|----------|-----------|
| Framework | Phalcon 5 — `Phalcon\Mvc\Micro` |
| Database | PostgreSQL (via `Phalcon\Db\Adapter\Pdo\Postgresql`) |
| ORM | Phalcon ORM — `Phalcon\Mvc\Model` (Active Record) |
| Migrasi | **Phinx** (`robmorgan/phinx`) |
| Autentikasi | JWT (`firebase/php-jwt`), algoritma HS256 |
| Email/OTP | PHPMailer (SMTP) — alternatif: Resend |
| Konfigurasi | `vlucas/phpdotenv` (`.env`) |
| Dependensi | Composer |

---

## 2. Struktur Direktori

```
ika-jtk-backend/
├── app/
│   ├── config/
│   │   ├── router.php       # Definisi semua rute API (MicroCollection)
│   │   └── services.php     # Service DI: koneksi 'db' + 'config'
│   ├── controllers/         # Logika endpoint (Auth, Election, Admin*, Upload)
│   ├── middleware/
│   │   └── AuthMiddleware.php  # Validasi JWT + RBAC sebelum controller
│   └── models/              # Representasi tabel (Phalcon\Mvc\Model)
├── db/
│   ├── migrations/          # Migrasi Phinx (skema database, terversi)
│   └── seeds/               # Seeder Phinx (data awal, mis. admin default)
├── public/
│   ├── index.php            # Entry point — bootstrap aplikasi
│   ├── .htaccess            # Rewrite URL (untuk Apache production)
│   └── uploads/             # File upload (avatar, dokumen)
├── docs/
│   └── WORKFLOW.md          # Dokumen ini
├── phinx.php                # Konfigurasi Phinx (baca DATABASE_URL dari .env)
├── composer.json            # Dependensi + script shortcut
└── .env                     # Konfigurasi rahasia (TIDAK di-commit)
```

---

## 3. Alur Request (Request Lifecycle)

Setiap request HTTP mengalir melalui urutan berikut:

```
Client (CMS / Flutter / Portal)
        │
        ▼
public/index.php  ── bootstrap:
        │            1. Load vendor/autoload.php
        │            2. Load .env (Dotenv)
        │            3. Buat FactoryDefault DI
        │            4. Include services.php  (daftar service 'db' & 'config')
        │            5. Buat Phalcon\Mvc\Micro
        │            6. Include router.php     (daftar semua rute)
        │            7. Attach AuthMiddleware ke EventsManager
        │            8. Pasang CORS (before) + JSON response (after)
        ▼
EventsManager → AuthMiddleware::beforeExecuteRoute()
        │            • Lewati jika OPTIONS (preflight CORS)
        │            • Lewati jika rute publik (lihat daftar unprotectedRoutes)
        │            • Selain itu: wajib header  Authorization: Bearer <JWT>
        │            • Decode JWT → cek role untuk rute /api/admin (RBAC)
        │            • Simpan userId & userRole ke DI (shared)
        ▼
Controller (mis. AuthController::login)
        │            • Ambil input: getJsonRawBody(true) ?: getPost()
        │            • Query/ubah data lewat Model (Active Record)
        │            • Set status code via $this->response->setStatusCode()
        │            • RETURN array  (bukan echo)
        ▼
Micro::after()  → array hasil controller di-encode jadi JSON otomatis
        ▼
Response JSON ke client
```

> **Catatan penting:** controller cukup **`return` sebuah array** — hook `after()`
> di `index.php` yang meng-encode-nya menjadi JSON. Jangan `echo` manual.

---

## 4. Autentikasi & Otorisasi (JWT + RBAC)

Diatur sepenuhnya di [`app/middleware/AuthMiddleware.php`](../app/middleware/AuthMiddleware.php).

### Rute publik (tanpa token)
```
POST /api/auth/login          POST /api/admin/auth/login
POST /api/auth/register       GET  /api/elections
POST /api/auth/verify-email   GET  /api/elections/{id}
POST /api/auth/resend-otp
```

### Rute terproteksi
Semua rute lain wajib header `Authorization: Bearer <token>`. Token di-decode;
jika gagal → `401`. `userId` & `userRole` dari payload disimpan ke DI agar bisa
dibaca controller via `$this->di->getShared('userId')`.

### RBAC untuk `/api/admin/*`
Role yang dikenal: `Super Admin`, `Admin Verifikator`, `Admin Viewer`, `Admin`.

| Aturan | Detail |
|--------|--------|
| Akses panel admin | Role harus salah satu dari daftar di atas, jika tidak → `403` |
| `/api/admin/users` | Hanya **Super Admin** |
| `/api/admin/alumni` (POST/PUT/DELETE) | **Super Admin** atau **Admin Verifikator** |
| Modul admin lain (POST/PUT/DELETE) | Hanya **Super Admin** (selain itu Viewer = read-only) |

### Membuat token (di controller)
```php
$secret  = $this->di->get('config')['jwt_secret'];
$payload = ['id' => $alumni->id, 'email' => $alumni->email, 'exp' => time() + 7*24*3600];
$token   = \Firebase\JWT\JWT::encode($payload, $secret, 'HS256');
```

---

## 5. Pola Controller (Convention)

Lihat contoh nyata di [`AuthController`](../app/controllers/AuthController.php).
Pola yang konsisten dipakai di seluruh project:

```php
public function namaAksi()
{
    // 1. Ambil input (JSON body, fallback ke form-data)
    $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

    // 2. Validasi
    if (empty($request['field'])) {
        $this->response->setStatusCode(400);
        return ['message' => 'Field wajib diisi'];
    }

    // 3. Query/mutasi via Model
    $row = NamaModel::findFirst([
        'conditions' => 'kolom = ?0',
        'bind'       => [$nilai],
    ]);

    // 4. Set status + return array (JSON otomatis)
    $this->response->setStatusCode(200);
    return ['data' => $row->toArray()];
}
```

**Konvensi penting:**
- Ambil user yang sedang login: `$this->di->getShared('userId')`.
- Selalu **hapus `password`** sebelum mengembalikan data user (`unset($data['password'])`).
- Kolom JSON (`pekerjaan`, `prestasi`, `misi`, `pengalaman`, dll.) disimpan sebagai
  string JSON; saat input array, `json_encode()` dulu; saat output, `json_decode()`.
- Mengembalikan URL file: normalisasi path relatif → absolut bila perlu.

---

## 6. Pola Model (Active Record)

Lihat [`app/models/`](../app/models/). Setiap tabel = satu class `extends Phalcon\Mvc\Model`.

```php
class Election extends Model
{
    public $id;
    public $judul;
    // ... kolom lain sebagai properti publik

    public function initialize()
    {
        $this->setSource("Election");                 // nama tabel (case-sensitive)
        $this->hasMany('id', Candidate::class, 'electionId', ['alias' => 'Candidates']);
    }

    public function beforeValidationOnCreate()
    {
        if (empty($this->id)) {
            $this->id = /* generate UUID/hex manual */;  // ID bukan auto-increment
        }
        $this->createdAt = date('Y-m-d H:i:s');
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    public function beforeValidationOnUpdate()
    {
        $this->updatedAt = date('Y-m-d H:i:s');
    }
}
```

**Operasi umum:**
```php
NamaModel::find();                                              // semua
NamaModel::findFirst(['conditions' => 'x = ?0', 'bind' => [$v]]);
NamaModel::count(['conditions' => 'x <= ?0', 'bind' => [$v]]);
$m = new NamaModel(); $m->field = ...; $m->save();             // create/update
$m->delete();
```

> **Catatan:** `id` adalah `VARCHAR(255)` berisi UUID/hex yang dibuat di hook
> `beforeValidationOnCreate()`, **bukan** auto-increment. Karena itu migrasi
> mendeklarasikan primary key string (lihat bagian Migrasi).

---

## 7. Database & Migrasi (Phinx)

Skema dikelola dengan **Phinx** — migrasi terversi, mendukung rollback & seeding.
Konfigurasi: [`phinx.php`](../phinx.php) (membaca `DATABASE_URL` dari `.env`, satu
sumber dengan `app/config/services.php`).

### Shortcut Composer
```bash
composer db:setup          # migrate + seed sekaligus (instalasi awal)
composer migrate           # jalankan migrasi yang belum dijalankan
composer migrate:status    # lihat status migrasi
composer migrate:rollback  # batalkan migrasi terakhir
composer seed              # isi data awal (admin default)
composer migrate:create Nama   # buat file migrasi baru
composer seed:create Nama      # buat file seeder baru
```
> Shortcut composer default ke environment `development`. Untuk **production**,
> jalankan langsung: `php vendor/bin/phinx migrate -c phinx.php -e production`.

### Menambah perubahan skema (alur baku)
```bash
composer migrate:create TambahKolomXyz
# edit db/migrations/<timestamp>_tambah_kolom_xyz.php
composer migrate
```

Gunakan **Table API** dengan method `change()` agar rollback dibuat otomatis:
```php
public function change(): void
{
    $this->table('Alumni')
        ->addColumn('nomorWa', 'string', ['limit' => 50, 'null' => true])
        ->update();
}
```
Untuk membuat tabel baru (ingat: ID = string UUID, bukan auto-increment):
```php
$this->table('NamaTabel', ['id' => false, 'primary_key' => 'id'])
    ->addColumn('id', 'string', ['limit' => 255])
    ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
    ->create();
```
Tipe Postgres khusus didukung: `jsonb`, `boolean`, `text`, `integer`, `timestamp`.
Untuk kebutuhan yang tak tercakup Table API, pakai `$this->execute('<raw SQL>')`.

### Penting saat menambah tabel/kolom
Migrasi dan **Model harus konsisten**: nama tabel di migrasi = `setSource()` di model,
nama kolom = properti model (camelCase, case-sensitive). Skema adalah sumber
kebenaran untuk struktur; model adalah representasinya.

---

## 8. Konfigurasi (`.env`)

File `.env` **tidak di-commit** (di-`.gitignore`). Variabel yang dipakai:

```env
DATABASE_URL="postgresql://user:pass@localhost:5432/ika-jtk?schema=public"
JWT_SECRET="..."
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="email@gmail.com"
SMTP_PASS="app_password_gmail"
SMTP_FROM="Alumni IKA JTK <email@gmail.com>"
RESEND_API_KEY=""
```
Dibaca via `$_ENV[...]` di [`services.php`](../app/config/services.php) dan `phinx.php`.

---

## 9. Workflow Menambah Fitur Baru (End-to-End)

Misal menambah modul baru `/api/admin/sertifikat`:

1. **Migrasi** — buat tabel:
   ```bash
   composer migrate:create CreateSertifikatTable
   # isi change() dengan ->table('Sertifikat', ...)->create()
   composer migrate
   ```
2. **Model** — buat `app/models/Sertifikat.php` (`setSource("Sertifikat")`,
   properti = kolom, hook `beforeValidationOnCreate` untuk ID + timestamp).
3. **Controller** — buat `app/controllers/AdminSertifikatController.php`
   (method `index/show/create/update/delete`, ikuti pola di Bagian 5).
4. **Route** — daftarkan di [`app/config/router.php`](../app/config/router.php):
   ```php
   $c = new MicroCollection();
   $c->setHandler(new \App\Controllers\AdminSertifikatController())
     ->setPrefix('/api/admin/sertifikat');
   $c->get('/', 'index');
   $c->post('/', 'create');
   // ... put/delete
   $app->mount($c);
   ```
5. **Otorisasi** — rute `/api/admin/*` otomatis tunduk RBAC di `AuthMiddleware`.
   Sesuaikan aturan role di middleware bila perlu.
6. **Uji** — jalankan server, panggil endpoint dengan token yang sesuai.

---

## 10. Menjalankan Secara Lokal

```bash
composer install                      # pasang dependensi
# pastikan PostgreSQL berjalan & DATABASE_URL benar di .env
composer db:setup                     # buat tabel + admin default
php -S localhost:5000 -t public       # jalankan dev server
```
Server: `http://localhost:5000`. Admin default hasil seed: `admin@ikajtk.id` / `admin123`.

Untuk panduan deploy ke server Linux (tanpa Docker) — prasyarat, langkah migrasi
production, konfigurasi Nginx + PHP-FPM, dan troubleshooting — lihat
[`docs/DEPLOYMENT.md`](DEPLOYMENT.md).

---

## 11. Diagram Ringkas Modul

| Prefix Rute | Controller | Akses |
|-------------|-----------|-------|
| `/api/auth/*` | `AuthController` | publik (login/register) + alumni login (me/profile) |
| `/api/elections/*` | `ElectionController` | publik (list/detail), vote butuh login |
| `/api/upload/*` | `UploadController` | login |
| `/api/admin/auth/*` | `AdminAuthController` | publik (login), `me` butuh login |
| `/api/admin/users/*` | `AdminUserController` | Super Admin |
| `/api/admin/alumni/*` | `AdminAlumniController` | Super Admin / Verifikator (tulis) |
| `/api/admin/elections/*` | `AdminElectionController` | Super Admin (tulis) |
| `/api/admin/pemilu/*` | `AdminPemiluController` | Super Admin (tulis) |
| `/api/admin/berita/*` | `AdminBeritaController` | Super Admin (tulis) |
| `/api/admin/agenda/*` | `AdminAgendaController` | Super Admin (tulis) |
| `/api/admin/loker/*` | `AdminLokerController` | Super Admin (tulis) |
| `/api/admin/testimoni/*` | `AdminTestimoniController` | Super Admin (tulis) |
