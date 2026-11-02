# Arsitektur & Alur Modul Sistem IKA JTK

Dokumen ini berisi diagram arsitektur sistem 3-tier serta diagram alur (*block diagram*) yang **disusun secara spesifik berdasarkan uraian Modul Fungsional di Bab 3 (Sub-bab 3.1.2.1 sampai 3.1.2.6)**.

---

## 🏛️ Arsitektur Sistem 3-Tier (Decoupled Client-Server)

> **Visualisasi komunikasi antar komponen sistem IKA JTK:**

```mermaid
graph TD
    subgraph ClientLayer["Client Layer"]
        Portal["Portal Alumni (Flutter Web / Mobile)"]
        CMS["CMS Admin Panel (React + Vite)"]
    end

    subgraph APILayer["API Layer / Core Engine"]
        Router["Backend API Router (PHP Phalcon 5)"]
        Auth["JWT Auth & RBAC Middleware"]
        Email["Email Engine (PHPMailer SMTP)"]
    end

    subgraph DBLayer["Database & Storage Layer"]
        DB[("Database PostgreSQL")]
        Storage["Storage File Uploads (Ijazah / Foto)"]
    end

    Portal -->|REST API Requests JWT| Router
    CMS -->|REST API Requests JWT Admin| Router
    Router --> Auth
    Router -->|Kirim OTP & Email Notifikasi| Email
    Router -->|Simpan & Ambil Dokumen| Storage
    Auth --> DB
```

---

## 👥 1. Modul Keanggotaan dan Verifikasi (Sesuai 3.1.2.1)

> **Alur pendaftaran mandiri, validasi email OTP, hingga persetujuan dokumen ijazah oleh admin.**

```mermaid
graph TD
    subgraph ClientLayer["Client Layer"]
        Portal["Portal Alumni (Form Registrasi)"]
        CMS["CMS Admin (Approval Dashboard)"]
    end

    subgraph APILayer["API Layer / Core Engine"]
        RegAPI["Registration API (Upload Ijazah)"]
        OTPLogic["Email OTP Generator"]
        AuthLogic["Admin Approval Logic"]
    end

    subgraph DBLayer["Database & Storage Layer"]
        DBStore[("PostgreSQL (Tabel Alumni)")]
    end

    Portal -->|1. Submit Data & Ijazah| RegAPI
    RegAPI --> OTPLogic
    OTPLogic -->|2. Kirim Email OTP| Portal
    Portal -->|3. Verifikasi OTP| RegAPI
    RegAPI -->|4. Simpan Status: Pending| DBStore
    CMS -->|5. Tinjau Ijazah: Approve/Reject| AuthLogic
    AuthLogic -->|6. Update Status & Kirim Notif Penolakan/Persetujuan| DBStore
```

---

## 💼 2. Modul Portal Karir dan Lowongan Kerja (Sesuai 3.1.2.2)

> **Alur publikasi loker, sistem moderasi loker dari alumni, dan pengajuan lamaran.**

```mermaid
graph TD
    subgraph ClientLayer["Client Layer"]
        Portal["Portal Alumni (Fitur Karir)"]
        CMS["CMS Admin (Loker & Moderasi)"]
    end

    subgraph APILayer["API Layer / Core Engine"]
        JobAPI["Loker Controller"]
        ApplyAPI["Job Application Handler"]
    end

    subgraph DBLayer["Database & Storage Layer"]
        DBStore[("PostgreSQL (Tabel Loker & Lamaran)")]
    end

    CMS -->|Publikasi Loker Langsung| JobAPI
    Portal -->|Pengajuan Loker Baru| JobAPI
    JobAPI -->|Simpan Status: Butuh Moderasi| DBStore
    CMS -->|Review & Moderasi Pengajuan Loker| JobAPI
    Portal -->|Apply Loker & Upload Berkas Lamaran| ApplyAPI
    ApplyAPI -->|Simpan Data Lamaran| DBStore
```

---

## 📰 3. Modul Berita dan Agenda Kegiatan (Sesuai 3.1.2.3)

> **Alur publikasi informasi dan registrasi kehadiran agenda beserta notifikasi email.**

```mermaid
graph TD
    subgraph ClientLayer["Client Layer"]
        CMS["CMS Admin (Post Berita/Agenda)"]
        Portal["Portal Alumni (Daftar & Agenda)"]
    end

    subgraph APILayer["API Layer / Core Engine"]
        ContentAPI["Content Management API"]
        EventAPI["Event Registration Logic"]
        EmailWorker["Email Notification Engine"]
    end

    subgraph DBLayer["Database & Storage Layer"]
        DBStore[("PostgreSQL (Tabel Berita & Agenda)")]
    end

    CMS -->|Publish Artikel atau Agenda Seminar Reuni| ContentAPI
    ContentAPI --> DBStore
    Portal -->|Klik 'Daftar Kegiatan' pada Agenda| EventAPI
    EventAPI -->|Simpan Partisipasi| DBStore
    EventAPI --> EmailWorker
    EmailWorker -->|Kirim Notifikasi Konfirmasi Pendaftaran| Portal
```

---

## 🗳️ 4. Modul E-Voting Pemilu Ketua IKA JTK (Sesuai 3.1.2.4)

> **Alur manajemen pemilu, pemungutan suara aman (1 akun 1 suara), dan pemantauan langsung.**

```mermaid
graph TD
    subgraph ClientLayer["Client Layer"]
        Portal["Portal Alumni (Layar E-Voting)"]
        CMS["CMS Admin (Manajemen Pemilu)"]
    end

    subgraph APILayer["API Layer / Core Engine"]
        ElectionAPI["Election Controller"]
        VoteLogic["Vote Processor & 1-Account-1-Vote Validation"]
    end

    subgraph DBLayer["Database & Storage Layer"]
        DBStore[("PostgreSQL (elections, candidates, vote_records)")]
    end

    CMS -->|Buat Sesi & Daftarkan Kandidat| ElectionAPI
    ElectionAPI --> DBStore
    Portal -->|Submit Suara Terenkripsi| VoteLogic
    VoteLogic -->|Validasi Kriteria Alumni| DBStore
    CMS -->|Pantau Perolehan Suara Langsung| ElectionAPI
    Portal -->|"Pemantauan Hasil (Jika Diaktifkan)"| ElectionAPI
```

---

## 📇 5. Modul Direktori Alumni dan Profil (Sesuai 3.1.2.5)

> **Alur pencarian jaringan profesional alumni dan pembuatan kartu identitas grafis.**

```mermaid
graph TD
    subgraph ClientLayer["Client Layer"]
        Portal["Portal Alumni (Pencarian & Profil)"]
    end

    subgraph APILayer["API Layer / Core Engine"]
        SearchAPI["Search & Filter Engine"]
        IDCardAPI["Graphic ID Card Generator"]
        Pagination["Server-Side Pagination Logic"]
    end

    subgraph DBLayer["Database & Storage Layer"]
        DBStore[("PostgreSQL (Data Alumni Terverifikasi)")]
    end

    Portal -->|Pencarian by Prodi/Angkatan/Pekerjaan| SearchAPI
    SearchAPI --> Pagination
    Pagination --> DBStore
    Portal -->|Request Pembuatan Kartu Identitas Grafis| IDCardAPI
    IDCardAPI -->|Generate Graphic Card| Portal
```

---

## ⚙️ 6. Modul Audit Log dan Pengaturan Sistem (Sesuai 3.1.2.6)

> **Alur perekaman jejak aktivitas admin, pengaturan hak akses, dan konfigurasi portal dinamis.**

```mermaid
graph TD
    subgraph ClientLayer["Client Layer"]
        CMS["CMS Admin (Pengaturan & Log)"]
    end

    subgraph APILayer["API Layer / Core Engine"]
        ConfigAPI["Portal Settings & User Agreement API"]
        AuditAPI["Audit Logger & Role Access Middleware"]
    end

    subgraph DBLayer["Database & Storage Layer"]
        DBStore[("PostgreSQL (portal_configs, audit_logs)")]
    end

    CMS -->|Update Tampilan/User Agreement/Hak Akses| ConfigAPI
    ConfigAPI --> DBStore
    CMS -->|"Eksekusi Aksi Penting (Misal: Approve Akun)"| AuditAPI
    AuditAPI -->|Otomatis Catat Waktu & Identitas Pengguna| DBStore
```
