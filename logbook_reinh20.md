# 📋 Logbook Kegiatan Magang — reinh20 (Reinbrandt)
**Proyek:** Website IKA JTK (Portal Alumni, CMS, Backend)
**Repository:** ika-jtk-portal | ika-jtk-cms | ika-jtk-backend
**Periode:** 22 Juni 2026 – 30 Juli 2026

---

## 📅 Senin, 22 Juni 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Mengimplementasikan sistem manajemen pemilu di backend (`implement backend election management`)
- **[CMS]** Mengintegrasikan modul pemilu (election) dengan backend API di sisi CMS
- **[Portal]** Mengintegrasikan halaman pemilu (Pemilu) dengan backend API nyata menggunakan provider Flutter

### Ringkasan:
Hari pertama difokuskan pada pembangunan fitur **Pemilihan Umum (Pemilu)** secara end-to-end dari backend hingga tampilan portal alumni.

---

## 📅 Selasa, 23 Juni 2026
*Tidak ada commit dari reinh20 pada tanggal ini.*

---

## 📅 Rabu, 24 Juni 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Menyempurnakan logika voting, manajemen kandidat, fix CORS middleware, dan perbaikan fitur alumni
- **[Backend]** Menyelesaikan error API pemilu dan menghitung `totalVoter`
- **[Backend]** Menambahkan script pembuatan tabel `vote_records`
- **[CMS]** Menyimpan progres fitur election sebelum merge branch
- **[CMS]** Merge branch election ke main dan resolve konflik
- **[CMS]** Menghapus mock import yang menyebabkan build Vite error
- **[Portal]** Mengintegrasikan pemilu dengan backend API nyata

### Ringkasan:
Fokus pada **penyempurnaan dan stabilisasi fitur Pemilu**, termasuk penanganan error API, penghitungan total pemilih, dan sinkronisasi antar komponen.

---

## 📅 Kamis, 25 Juni 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Update endpoint pemilu dan refactor `AdminPemiluController`
- **[Backend]** Resolve konflik merge dan integrasi perubahan remote
- **[CMS]** Fix field mapping foto kandidat pada `PemiluFormPage`
- **[CMS]** Update tipe election dan integrasi API
- **[CMS]** Fix render HTML untuk deskripsi di detail page, strip HTML di list page
- **[CMS]** Resolve konflik merge di `PemiluFormPage.tsx`
- **[Portal]** Strip HTML dari field deskripsi dan perbaikan lokal lainnya

### Ringkasan:
Perbaikan dan penyempurnaan lebih lanjut pada **fitur Pemilu**, terutama pembenahan form kandidat, rendering konten, dan sinkronisasi kode.

---

## 📅 Jumat, 26 Juni 2026
**Repo:** Backend, Portal

### Kegiatan:
- **[Backend]** Fix bug case-sensitivity pada status verifikasi dan tambah router untuk static CORS
- **[Backend]** Tambah script `fix_tables` dan update `.gitignore`
- **[Portal]** Menambah komponen `CandidateAvatar` dengan fallback inisial dinamis dan pembersihan rich text HTML
- **[Portal]** Update `pubspec.lock` dan aset environment

### Ringkasan:
Perbaikan bug **status verifikasi** dan penambahan komponen avatar kandidat di portal.

---

## 📅 Minggu, 29 Juni 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Perbaikan lokalisasi halaman pemilu dan penanganan empty state
- **[Backend]** Cleanup temporary helper scripts dan update `AdminElectionController`
- **[CMS]** Perbaikan form halaman pemilu (update `PemiluFormPage`)
- **[CMS]** Perbaikan lokalisasi pada form pemilu
- **[Portal]** Menambah loading indicator dan empty state untuk detail kandidat dan list pemilu
- **[Portal]** Update tampilan halaman pemilu dan presentasi kandidat
- **[Portal]** Menghapus file `.env` dari git tracking, tambah `.gitignore` untuk `.env`

### Ringkasan:
Perbaikan **UI/UX halaman Pemilu** — tampilan empty state, loading indicator, dan lokalisasi teks.

---

## 📅 Selasa, 30 Juni 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Menambahkan kolom `createdAt` dan `updatedAt` ke semua tabel database (audit trail)
- **[Backend]** Menambahkan kolom `deletedAt` ke semua tabel + partial unique index (soft delete)
- **[Backend]** Mengimplementasikan soft delete pada semua method delete
- **[Backend]** Menambahkan endpoint API publik untuk **berita, agenda, loker**
- **[Backend]** Mengimplementasikan **portal config key-value storage** di database
- **[Backend]** Menambahkan endpoint **ringkasan pemilu** untuk CMS dan portal
- **[Backend]** Mengunci jadwal pemilu setelah election dimulai (lock pemilu aktif)
- **[Backend]** Implementasi **auto-numbering** format `YYYYMMDDNNNN` untuk berita, agenda, loker
- **[Backend]** Fix `PortalConfig` — selalu json_encode, handle null, tambah error logging
- **[CMS]** Integrasi halaman Portal Settings dengan backend API
- **[CMS]** Menambahkan live election summary dengan auto-refresh di halaman detail CMS
- **[CMS]** Menonaktifkan input jadwal dan tampilkan pesan lock ketika election sudah mulai
- **[CMS]** Fix support rute `/admin/login` dan redirect saat Vite base adalah `/admin/`
- **[Portal]** Menggantikan mock data dengan API call nyata untuk berita, agenda, loker
- **[Portal]** Menambahkan live election summary section dengan auto-refresh timer
- **[Portal]** Mengintegrasikan portal settings ke Flutter portal (site name, hero, about, features, FAQ, contacts)
- **[Portal]** Menambahkan pembaruan otomatis portal config setiap 15 detik

### Ringkasan:
Hari paling produktif — implementasi besar-besaran meliputi **audit trail database, soft delete, API publik, portal config dinamis, dan integrasi live election.**

---

## 📅 Rabu, 1 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Menambahkan konfigurasi **Struktur Organisasi** dan seeder/migration
- **[Backend]** Memperbaiki endpoint PortalAlumniController dan registrasi rute API
- **[Backend]** Fix nama kolom `roleName` → `name` pada tabel AdminRole
- **[Backend]** Fix kompatibilitas return type dan nama kolom seeder
- **[Backend]** Fix URL gambar relatif otomatis pada konfigurasi portal
- **[CMS]** Menambahkan fitur manajemen **Struktur Organisasi** langsung di tab Tentang
- **[CMS]** Tambah upload gambar dan live search box untuk pilih alumni terverifikasi
- **[CMS]** Kustomisasi posisi, ukuran logo, posisi latar, dan overlay banner **Tentang** di CMS
- **[CMS]** Fix endpoint upload banner dari `/upload/general` ke `/upload`
- **[Portal]** Menampilkan struktur organisasi dinamis dari CMS config di halaman Tentang
- **[Portal]** Menambahkan model `AboutBannerData` dan banner hero dinamis dari database
- **[Portal]** Render deskripsi portal sebagai HTML menggunakan `flutter_widget_from_html_core`
- **[Portal]** Update data dan provider alumni serta direktori alumni

### Ringkasan:
Fokus pada **halaman Tentang** — manajemen struktur organisasi, banner dinamis, dan rendering HTML untuk konten portal.

---

## 📅 Rabu, 2 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Membuat endpoint testimoni publik dan fix case-insensitive visibility check
- **[Backend]** Randomize dan batasi testimoni publik maksimum 5 buah
- **[CMS]** Menambahkan **modal crop gambar** (ImageCrop component)
- **[CMS]** Replace tombol preview dengan direct slide thumbnail preview di hero carousel
- **[CMS]** Align dan group pengaturan banner per kategori (Opacity, Ukuran, Posisi)
- **[Portal]** Membuat section testimoni **dinamis** dan fetch dari API
- **[Portal]** Auto-rotate banner alumni unggulan setiap 2 detik dengan animasi transisi
- **[Portal]** Fix URL avatar dan foto relatif menggunakan `resolveImageUrl`

### Ringkasan:
Pengembangan fitur **Testimoni publik** dan penyempurnaan **UX banner** dengan auto-rotate dan crop modal.

---

## 📅 Selasa, 6 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Implementasi `StickyFooterScrollView` di semua halaman portal
- **[Backend]** Fix optimasi storage field cleanup dan validasi uniqueness kandidat
- **[CMS]** Update wording `Unpublish` → `Arsipkan` untuk testimoni yang sudah published
- **[CMS]** Filter kandidat yang sudah terdaftar dari combobox alumni di form election
- **[CMS]** Fix `.gitignore` untuk file `.env`
- **[Portal]** Implementasi `StickyFooterScrollView` di semua halaman portal
- **[Portal]** Randomize dan batasi testimoni publik maks 5
- **[Portal]** Update auth provider dan halaman lupa password

### Ringkasan:
Implementasi **StickyFooterScrollView** secara menyeluruh di semua halaman portal untuk konsistensi layout.

---

## 📅 Senin, 7 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Fix cast `maintenance_mode` dan `allow_public_registration` sebagai boolean PHP (bukan 1/0)
- **[Backend]** Expose `maintenance_mode` di public portal config untuk Flutter portal
- **[Backend]** Fix upload: enforce 10MB max file size di backend dan `.htaccess`
- **[CMS]** Fix logo sidebar kini fetch dari portal config API
- **[CMS]** Ubah Mode Portal dari dua checkbox menjadi **radio button** (hanya bisa pilih satu)
- **[CMS]** Tambah validasi size file 10MB di client-side portal settings
- **[CMS]** Tambah field **Periode Pelantikan** di `PemiluFormPage`
- **[Portal]** Implementasi **halaman Maintenance Mode** — overlay ketika CMS set maintenance mode
- **[Portal]** Ubah judul election default menjadi `Pemilihan Belum Dimulai` saat tidak ada election aktif
- **[Portal]** Refactor layout halaman pemilu dan tambah dynamic period label

### Ringkasan:
Implementasi fitur **Maintenance Mode** di portal dan penyempurnaan pengaturan portal CMS (radio button mode, validasi file).

---

## 📅 Rabu, 8 Juli 2026
**Repo:** Backend

### Kegiatan:
- **[Backend]** Update backend changes (sinkronisasi perubahan)

### Ringkasan:
Sinkronisasi perubahan backend.

---

## 📅 Kamis, 10 Juli 2026
**Repo:** Backend

### Kegiatan:
- **[Backend]** Menambahkan **statistik real-time pemilu**, endpoint summary publik, validasi date chain, dan dynamic FAQ handling
- **[Backend]** Update election controllers, model, dan tambah migration `pengumuman pelantikan`
- **[Backend]** Fix: update election controller
- **[Backend]** Fix: tambah MainSeeder

### Ringkasan:
Pengembangan **statistik real-time pemilu** dan penyempurnaan endpoint election di backend.

---

## 📅 Senin, 13 Juli 2026
**Repo:** Backend, CMS

### Kegiatan:
- **[Backend]** Implementasi **field tags dan thumbnail** untuk berita, agenda, loker
- **[Backend]** Set batas maksimum upload avatar 5MB
- **[CMS]** Implementasi **thumbnail otomatis**, manajemen tags, dan dukungan SEO metadata
- **[CMS]** Implementasi tags freetext input dan SEO meta tags di halaman detail
- **[CMS]** Fix: pindahkan field TagInput dari banner section ke bawah editor utama

### Ringkasan:
Penambahan fitur **Tags, Thumbnail, dan SEO** untuk konten berita, agenda, dan loker.

---

## 📅 Selasa, 14 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Menambahkan **bot-meta pre-rendering middleware**, dokumentasi Nginx/Apache, dan fix query demografi pemilu
- **[Backend]** Menambahkan opsi **Sembunyikan Statistik** untuk pemilu
- **[CMS]** Menambahkan opsi **Hide Statistik** di form dan detail halaman pemilu
- **[Portal]** Update SEO helpers, halaman detail, dan tambah **social share widget**

### Ringkasan:
Penambahan fitur **SEO/pre-rendering untuk bot** dan opsi sembunyikan statistik pemilu.

---

## 📅 Rabu, 15 Juli 2026
**Repo:** Backend, Portal

### Kegiatan:
- **[Backend]** Initial commit: menambahkan proyek IKA JTK Portal, CMS, dan Backend ke repository

### Ringkasan:
Initial commit proyek ke repository baru.

---

## 📅 Kamis, 16 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Implementasi **validasi dan simpan userAgreement** pada saat registrasi alumni
- **[CMS]** Fix portal URL dinamis via env var untuk testing lokal
- **[Portal]** Tambah halaman **User Agreements** dan checkbox persetujuan pada registrasi alumni
- **[Portal]** Pembaruan desain panel statistik pemilih sementara dengan **tampilan modern dashboard UI**

### Ringkasan:
Implementasi fitur **Syarat & Ketentuan (User Agreement)** — halaman, validasi registrasi, dan integrasi checkbox.

---

## 📅 Jumat, 17 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Update struktur default `terms_conditions` — gabung tanggal dan intro dalam field content
- **[Backend]** Update judul default Terms menjadi "User Agreement (Syarat & Ketentuan Pengguna)"
- **[Backend]** Election bug fixes, update portal config, dan perbaikan routing
- **[CMS]** Rename Terms & Conditions → **User Agreement** di sidebar dan title
- **[CMS]** Gabungkan Tanggal, Intro, dan Isi Ketentuan menjadi **satu rich text editor**
- **[CMS]** Optimasi image compressor dengan hardware acceleration dan wait cursor / error handling
- **[CMS]** Update form pemilu, cleanup portal settings, dan halaman user agreements
- **[CMS]** Autofill username di halaman login admin tanpa mengisi password
- **[Portal]** Integrasi **flutter_image_compress** untuk kompresi gambar berkualitas tinggi di crop dialog dan edit profil
- **[Portal]** Implementasi GPU Skia downscaling saat crop (maks 1080px) — 10x lebih cepat
- **[Portal]** Fix koordinat crop yang bergeser — mapping `srcRect` langsung ke `targetW × targetH`
- **[Portal]** Improve UX portal: section scroll, upload error handling, loading cursor, statistik layout fix
- **[Portal]** Align tombol "Lihat Detail Statistik" ke pojok kanan atas label STATISTIK
- **[Portal]** Autofill username pada login page portal tanpa mengisi password

### Ringkasan:
Minggu paling intense — refactor besar pada **User Agreement, image compression dengan GPU, dan UX pemilu**.

---

## 📅 Senin, 20 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Implementasi **IP whitelist restriction** untuk login endpoint
- **[Backend]** Optimasi kualitas kompresi gambar dan bug fixes
- **[CMS]** Enforce batas ketat 5MB dan dimensi 1080px untuk semua upload di CMS
- **[CMS]** Optimasi kualitas kompresi gambar
- **[Portal]** Fix bug scrolling anchor dengan menonaktifkan lazy layout di `StickyFooterScrollView`
- **[Portal]** Tambah nama situs & logo di halaman login, enforce batas strict upload gambar
- **[Portal]** Validasi form dan filter agenda upcoming

### Ringkasan:
Perbaikan keamanan (**IP whitelist**), optimasi **kompresi gambar**, dan perbaikan scroll di portal.

---

## 📅 Selasa, 21 Juli 2026
**Repo:** Backend, Portal

### Kegiatan:
- **[Backend]** Tambah filter `hasGrafis` untuk notable alumni
- **[Portal]** Implementasi **server-side pagination** untuk alumni grafis dan logika auto-scroll anchor yang robust
- **[Portal]** Fix: handle respons array maupun object dari API providers
- **[Portal]** Tambah layout CTA banner Pemilu Versi 3 (top CTA banner)

### Ringkasan:
Implementasi **server-side pagination untuk alumni grafis** dan perbaikan handling respons API.

---

## 📅 Selasa, 22 Juli 2026
**Repo:** CMS, Portal

### Kegiatan:
- **[CMS]** Hapus pembatasan ukuran file 50MB
- **[CMS]** Optimasi render canvas high-res image untuk crop modal
- **[CMS]** Set target kompresi default gambar < 500KB
- **[CMS]** Izinkan seleksi foto hingga 50MB, auto-compress output ke < 5MB
- **[CMS]** Fix validasi 5MB untuk upload avatar alumni
- **[Portal]** Sama seperti CMS — hapus batasan 50MB, optimasi crop preview, target kompresi < 500KB
- **[Portal]** Izinkan foto hingga 50MB, compress ke < 5MB
- **[Portal]** Fix: tambah mounted check sebelum crop dialog
- **[Portal]** Fix validasi 5MB untuk upload avatar

### Ringkasan:
Penyempurnaan besar pada **sistem crop dan kompresi gambar** — fleksibel 50MB input, output otomatis < 5MB.

---

## 📅 Senin, 27 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Hapus ekstensi `.webp` dari daftar ekstensi yang diizinkan
- **[Backend]** Hapus `test_email.php` dan sinkronisasi perubahan
- **[CMS]** Hapus continuous polling dari halaman Pemilu
- **[CMS]** Fix: ImageCrop transparent PNG issue & Pemilu page blinking
- **[Portal]** Hapus konversi WebP dan batasi ekstensi upload hanya JPG/PNG
- **[Portal]** Fix alignment navbar layout dengan centering `SingleChildScrollView`

### Ringkasan:
Menghapus dukungan **WebP** dari sistem upload dan perbaikan UI (navbar, crop PNG transparent).

---

## 📅 Selasa, 28 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Fix thumbnail generation yang salah memaksa ekstensi `.webp`
- **[Backend]** Izinkan akses publik ke endpoint ringkasan election
- **[Backend]** Amankan API error handling agar tidak expose raw exception
- **[Backend]** Tambah error logging di semua block catch controller
- **[Backend]** Tambah fallback `avatarUrl` untuk `fotoUrl` kandidat di API alumni
- **[Backend]** Hapus utility scripts
- **[CMS]** Hapus semua kompresi dan validasi WebP
- **[CMS]** Restrict upload file hanya JPG dan PNG di semua komponen
- **[CMS]** Update logika toggle statistik Pemilu dan label menjadi 'Tampilkan'
- **[CMS]** Hapus "(Syarat & Ketentuan)" dari pengaturan User Agreement
- **[Portal]** Gunakan high resolution images untuk hero banner dan fix layout banner alumni
- **[Portal]** Ganti `ImagePicker` dengan `FilePicker` untuk enforce tipe file JPG/PNG
- **[Portal]** Fix navbar alignment
- **[Portal]** Fix candidate photo fallback di public profile page
- **[Portal]** Hapus "(Syarat & Ketentuan)" dari teks halaman register

### Ringkasan:
Perbaikan menyeluruh: **keamanan API, cleanup WebP, strict JPG/PNG, dan fallback foto kandidat**.

---

## 📅 Rabu, 29 Juli 2026
**Repo:** Portal

### Kegiatan:
- **[Portal]** Fix: UI-Avatars mengembalikan SVG, tambah `format=png` agar kompatibel dengan Flutter Web
- **[Portal]** Tambah **fallback avatar inisial** untuk pengguna tanpa foto
- **[Portal]** Fix: ekstraksi response wrapper pada `Alumni.getDetail()`

### Ringkasan:
Perbaikan **avatar fallback** dan kompatibilitas Flutter Web dengan layanan UI-Avatars.

---

## 📅 Rabu, 30 Juli 2026
**Repo:** Backend, CMS, Portal

### Kegiatan:
- **[Backend]** Fix validasi ekstensi upload — pastikan hanya `.jpg`, `.jpeg`, `.png` yang diterima secara konsisten
- **[CMS]** Fix TypeScript errors: hapus unused import `getAvatarUrl` di `AgendaListPage`, `AlumniListPage`, `BeritaListPage`, `LokerListPage`, dan `TestimoniListPage`
- **[CMS]** Fix TypeScript error: tambah field `imageType` pada tipe `CropTarget` di `ImageCropModal` dan `PortalSettingsPage`
- **[CMS]** Fix bug tab filter **"Berlangsung"** pada halaman daftar Pemilu yang menampilkan nilai 0 meski ada data aktif
- **[Portal]** Fix `agenda_provider.dart` — perbaikan provider agenda agar data tampil dengan benar
- **[Portal]** Fix `profile_page.dart` — perbaikan tampilan halaman profil member
- **[Portal]** Fix `image_crop_dialog.dart` — perbaikan dialog crop gambar di portal Flutter
- **[CMS & Portal]** Commit, pull, dan push seluruh perubahan ke repository

### Ringkasan:
Perbaikan **bug TypeScript** di CMS (unused imports, tipe `imageType`), fix **tab filter Pemilu**, dan penyempurnaan beberapa komponen Flutter portal (agenda, profil, crop dialog). Semua perubahan di-push ke repository.

---

## 📊 Rekap Total Kontribusi

| Tanggal | Backend | CMS | Portal | Total |
|---------|---------|-----|--------|-------|
| 22 Jun | ✅ | ✅ | ✅ | 3 repo |
| 24 Jun | ✅ | ✅ | ✅ | 3 repo |
| 25 Jun | ✅ | ✅ | ✅ | 3 repo |
| 26 Jun | ✅ | — | ✅ | 2 repo |
| 29 Jun | ✅ | ✅ | ✅ | 3 repo |
| 30 Jun | ✅ | ✅ | ✅ | 3 repo |
| 1 Jul | ✅ | ✅ | ✅ | 3 repo |
| 2 Jul | ✅ | ✅ | ✅ | 3 repo |
| 6 Jul | ✅ | ✅ | ✅ | 3 repo |
| 7 Jul | ✅ | ✅ | ✅ | 3 repo |
| 8 Jul | ✅ | — | — | 1 repo |
| 10 Jul | ✅ | — | — | 1 repo |
| 13 Jul | ✅ | ✅ | — | 2 repo |
| 14 Jul | ✅ | ✅ | ✅ | 3 repo |
| 15 Jul | ✅ | — | ✅ | 2 repo |
| 16 Jul | ✅ | ✅ | ✅ | 3 repo |
| 17 Jul | ✅ | ✅ | ✅ | 3 repo |
| 20 Jul | ✅ | ✅ | ✅ | 3 repo |
| 21 Jul | ✅ | — | ✅ | 2 repo |
| 22 Jul | — | ✅ | ✅ | 2 repo |
| 27 Jul | ✅ | ✅ | ✅ | 3 repo |
| 28 Jul | ✅ | ✅ | ✅ | 3 repo |
| 29 Jul | — | — | ✅ | 1 repo |
| 30 Jul | ✅ | ✅ | ✅ | 3 repo |

---

## 🏷️ Fitur Utama yang Dikerjakan

| Fitur | Komponen |
|-------|----------|
| Sistem Pemilu (Election) end-to-end | Backend + CMS + Portal |
| Portal Config dinamis (site name, hero, FAQ, contacts) | Backend + CMS + Portal |
| Soft Delete semua entitas | Backend |
| Struktur Organisasi di halaman Tentang | Backend + CMS + Portal |
| User Agreement (Syarat & Ketentuan) | Backend + CMS + Portal |
| Tags, Thumbnail, SEO untuk berita/agenda/loker | Backend + CMS |
| Image Compression dengan GPU (flutter_image_compress) | Portal + CMS |
| Maintenance Mode | Backend + Portal |
| IP Whitelist untuk login admin | Backend |
| Alumni Grafis (server-side pagination) | Backend + Portal |
| Fallback Avatar Inisial | Portal |
| Social Share Widget | Portal |
| Bot Meta Pre-rendering Middleware | Backend |
