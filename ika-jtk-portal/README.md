# ika_jtk_portal

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment Setup (.env)

Aplikasi portal ini membutuhkan file konfigurasi `.env` untuk berjalan dengan baik, terutama untuk menghubungkan aplikasi ke backend server yang tepat.

**Langkah Instalasi:**
1. Salin (copy) file `.env.example` dan ubah namanya menjadi `.env` di dalam root folder proyek ini.
   ```bash
   cp .env.example .env
   ```
2. Buka file `.env` yang baru saja dibuat.
3. Sesuaikan *value* dari `API_BASE_URL` ke alamat server backend Anda berjalan. 
   *(Contoh jika berjalan secara lokal: `http://localhost:5000`)*

**Peringatan Penting:** 
Jangan pernah meng-commit file `.env` asli Anda ke repositori (file ini sudah dimasukkan ke `.gitignore`). Selalu commit perubahan variabel pada `.env.example` sebagai referensi.
