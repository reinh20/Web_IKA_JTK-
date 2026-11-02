# BAB III
# KEGIATAN KP DAN PEMBAHASAN KRITIS

## 3.1. Deskripsi Kegiatan
Penulis melaksanakan kegiatan Kerja Praktik (KP) di PT. Pilar Timur Teknologi (Digital Oasis), Bandung, mulai tanggal 22 Juni hingga 31 Juli 2026 dengan sistem *Work From Office* (WFO) penuh, yaitu lima hari kerja dalam satu pekan (Senin–Jumat). Selama pelaksanaan kerja praktik, penulis berkontribusi dalam pengembangan Sistem Informasi Alumni IKA JTK yang terdiri atas Backend API, CMS Admin Panel, dan Portal Alumni. Kegiatan diawali dengan proses adaptasi terhadap lingkungan kerja, pemahaman alur bisnis sistem, serta konfigurasi lingkungan pengembangan agar sesuai dengan standar tim.

Selanjutnya, penulis terlibat dalam pengembangan berbagai fitur utama sistem, dengan fokus teknis pada modul Pemilihan Umum (E-Voting), manajemen konten portal dinamis, pengolahan berkas multimedia (gambar), optimasi mesin pencari (SEO), serta peningkatan keamanan jaringan (*API security*). Penulis juga berkontribusi secara signifikan pada pengembangan fitur Testimoni, penyempurnaan fitur Syarat & Ketentuan Pengguna (*User Agreement*), hingga implementasi *Maintenance Mode*. Selain pengembangan fitur baru, penulis turut melakukan optimasi performa melalui penerapan *client-side processing* (kompresi gambar GPU) dan *server-side pagination* agar aplikasi menjadi lebih responsif dan ringan saat digunakan.

Menjelang penyelesaian proyek, penulis berfokus pada audit keamanan antarmuka pemrograman aplikasi (API), peningkatan stabilitas melalui penanganan berbagai kondisi *error*, serta penyempurnaan fitur berdasarkan hasil pengujian dan masukan dari tim pengembang. Seluruh rangkaian kegiatan memberikan pengalaman dalam proses pengembangan perangkat lunak secara kolaboratif, mulai dari implementasi fitur, pengujian, hingga perbaikan sistem. Sebagai tahap akhir, penulis menyusun laporan kerja praktik sebagai dokumentasi atas kegiatan yang telah dilaksanakan sesuai dengan ketentuan yang tercantum dalam Buku Panduan Kerja Praktik 2025.

### 3.1.1. Web IKA JTK Polban
IKA JTK Polban merupakan platform digital resmi Ikatan Keluarga Alumni Jurusan Teknik Komputer dan Informatika (JTK) Politeknik Negeri Bandung yang dirancang sebagai ekosistem terpadu untuk menghubungkan alumni dari berbagai angkatan dan program studi. Sistem ini terdiri atas tiga komponen utama, yaitu Portal Alumni berbasis Flutter, CMS Admin Panel berbasis React dan TypeScript, serta Backend API berbasis PHP dengan database PostgreSQL. Ketiga komponen tersebut saling terintegrasi melalui RESTful API sehingga mampu mendukung pertukaran data secara efisien menggunakan protokol HTTP dan format JSON.

Sistem IKA JTK Polban dikembangkan untuk mendukung pengelolaan data alumni secara terpusat, proses verifikasi keanggotaan yang aman, pengembangan karier dan jejaring alumni, penyebaran informasi serta agenda kegiatan, dan pelaksanaan pemilihan Ketua IKA JTK secara daring. Untuk mewujudkan tujuan tersebut, sistem menyediakan berbagai modul yang mendukung kebutuhan alumni maupun pengurus organisasi dalam mengelola data, layanan, dan aktivitas kealumnian secara terintegrasi.

### 3.1.2. Modul Fungsional Sistem
**1. Keanggotaan dan Verifikasi Alumni**
Modul keanggotaan merupakan pintu masuk utama bagi alumni untuk bergabung dalam platform IKA JTK. Alumni mendaftar secara mandiri melalui Portal Alumni dengan mengisi data diri dan mengunggah dokumen ijazah sebagai bukti kelulusan. Sistem kemudian mengirimkan kode OTP (One-Time Password) ke alamat email alumni untuk memverifikasi keabsahan akun. Setelah verifikasi email berhasil, pengurus IKA JTK melalui CMS Admin akan meninjau dokumen ijazah yang diunggah dan memutuskan untuk menyetujui atau menolak keanggotaan. Alumni yang telah disetujui dapat mengakses seluruh fitur platform, sementara alumni yang ditolak akan menerima notifikasi alasan penolakan beserta kesempatan untuk memperbaiki dan mengunggah ulang dokumen. 

**2. Portal Karir dan Lowongan Kerja**
Modul portal karir menyediakan wadah bagi alumni untuk mengakses dan berbagi informasi lowongan kerja. Alumni terverifikasi dapat menelusuri serta memfilter lowongan yang tersedia berdasarkan kategori atau bidang pekerjaan, kemudian melamar secara langsung melalui portal dengan mengunggah berkas lamaran. Selain itu, alumni juga dapat mengajukan postingan lowongan kerja baru yang akan masuk ke antrian moderasi admin sebelum dipublikasikan. Di sisi CMS, admin dapat membuat dan mempublikasikan lowongan kerja secara langsung, maupun meninjau dan memoderasi setiap pengajuan lowongan dari alumni untuk memastikan kesesuaiannya dengan kebijakan platform.

**3. Berita dan Agenda Kegiatan**
Modul berita dan agenda berfungsi sebagai media informasi resmi bagi seluruh alumni IKA JTK. Pengurus dapat mempublikasikan artikel berita, pengumuman resmi, serta informasi kegiatan kealumnian seperti seminar, reuni, dan gathering melalui CMS Admin. Alumni dapat mengakses seluruh informasi tersebut melalui Portal Alumni, termasuk mendaftarkan kehadiran pada kegiatan yang diminati. Sistem akan mengirimkan notifikasi email kepada alumni yang telah mendaftarkan kehadiran sebagai konfirmasi partisipasi mereka.

**4. E-Voting Pemilu Ketua IKA JTK**
Modul E-Voting dirancang untuk memfasilitasi proses pemilihan Ketua IKA JTK secara daring dengan sistem yang aman, terverifikasi, dan transparan. Penyelenggaraan pemilihan dikelola oleh admin melalui CMS, mulai dari pembuatan sesi pemilu, pendaftaran kandidat beserta profil visi dan misi, hingga pengaturan kriteria alumni yang berhak memilih. Alumni yang memenuhi syarat dapat mengakses menu E-Voting melalui Portal Alumni dan memberikan suara kepada kandidat pilihan mereka. Sistem menerapkan mekanisme satu akun satu suara untuk menjaga integritas hasil pemilihan, dan admin dapat memantau perkembangan perolehan suara secara langsung melalui CMS selama sesi pemilihan berlangsung. 

**5. Direktori Alumni dan Profil**
Modul direktori alumni memudahkan alumni untuk mencari dan terhubung dengan sesama alumni berdasarkan berbagai kriteria, seperti program studi, angkatan kelulusan, maupun bidang pekerjaan. Setiap alumni terverifikasi memiliki profil publik yang dapat dilihat oleh sesama alumni, sehingga mendukung terbentuknya jaringan profesional antar alumni JTK Polban secara lebih luas dan terstruktur. Selain itu, sistem juga menyediakan fitur kartu identitas grafis alumni yang dapat diajukan dan diunduh sebagai identitas resmi keanggotaan IKA JTK.

**6. Audit Log dan Pengaturan Sistem**
Untuk menjaga keamanan dan akuntabilitas sistem, IKA JTK dilengkapi dengan modul Audit Log yang mencatat seluruh aktivitas penting yang dilakukan oleh admin maupun pengurus. Setiap tindakan seperti persetujuan keanggotaan, perubahan data, dan pengelolaan konten tercatat secara otomatis beserta informasi waktu dan identitas pengguna yang melakukannya. Selain itu, admin dapat mengelola peran dan hak akses pengguna CMS, mengatur syarat dan ketentuan penggunaan platform, serta melakukan konfigurasi tampilan portal sesuai kebutuhan organisasi.


## 3.2. Analisis Kritis

**1. Pelajaran Berharga Selama Kegiatan Kerja Praktik**
Selama melaksanakan Kerja Praktik di PT. Pilar Timur Teknologi (Digital Oasis), penulis memperoleh pengalaman mengenai proses pengembangan perangkat lunak di lingkungan industri. Penulis memahami pengembangan sistem yang terdiri atas Backend API, CMS Admin Panel, dan Portal Alumni yang saling terintegrasi melalui RESTful API. Selain itu, penulis juga mempelajari praktik terbaik dalam melakukan optimasi visibilitas sistem (*Search Engine Optimization* / SEO) pada kerangka kerja *Single Page Application* (SPA), serta teknik pengamanan *endpoint* API. 

Selain meningkatkan kemampuan teknis, penulis juga mengembangkan kemampuan komunikasi, kerja sama tim, serta manajemen waktu dalam ritme pengembangan *agile*. Pengalaman bekerja secara langsung dalam tim pengembang memberikan pemahaman yang lebih baik mengenai penerapan teori yang telah dipelajari di perkuliahan untuk mengatasi masalah skalabilitas dan performa aplikasi di dunia nyata.

**2. Analisis Pemecahan Masalah**
Selama pelaksanaan kerja praktik, salah satu tantangan terbesar yang dihadapi adalah manajemen data berkas multimedia dan sinkronisasi data secara *real-time*. Untuk mengatasi beban *bandwidth* akibat unggahan foto masif (hingga 50MB), tim memecahkan masalah ini dengan mendistribusikan beban komputasi ke sisi peramban (*client-side processing*). Solusi yang diterapkan adalah penggunaan *GPU Skia* di Flutter dan *Canvas HTML5* di React untuk memotong dan mengompresi gambar hingga ukurannya turun drastis di bawah 5MB sebelum ditransmisikan.

Selanjutnya, pada kendala penyajian data E-Voting agar terus mutakhir tanpa mengharuskan pengguna memuat ulang halaman (*refresh*), solusi yang diaplikasikan adalah teknik *HTTP Polling*. Aplikasi klien diprogram untuk melontarkan permintaan data ke *endpoint* statistik setiap interval 15 detik, sehingga menyajikan pengalaman peninjauan yang seketika (*real-time*). Dari sisi keamanan, penulis memberantas potensi kebocoran dari penanganan galat (*error handling*) API melalui *error masking* dengan mengembalikan respons galat standar yang aman dan tidak mengungkap rincian struktural server kepada publik.

**3. Perbandingan Teori dan Implementasi**
Secara teoritis, sistem informasi alumni bertujuan mengelola data secara terpusat dan menyediakan layanan yang mudah diakses oleh pengguna. Implementasi pada sistem IKA JTK telah sesuai dengan konsep tersebut melalui penggunaan Backend API sebagai pusat pengelolaan data yang melayani CMS Admin Panel dan Portal Alumni secara efisien. Konsep komputasi terdistribusi dan jaringan komputer yang dipelajari di bangku kuliah berpadu sempurna dengan arsitektur ini.

Namun, terdapat perbedaan menarik antara teori akademis dan implementasi siber di industri. Jika dalam teori sebuah sistem (*API*) diajarkan untuk merespons galat (*error*) dengan sedetail mungkin demi kemudahan identifikasi kesalahan (*debugging*), pada tahap produksi industri informasi tersebut justru harus dibatasi (*masking*) agar celah peladen tidak dieksploitasi oleh peretas. Demikian pula teori pengolahan citra digital teraplikasi secara nyata guna menghemat alokasi *bandwidth* perusahaan secara signifikan.

**4. Pengalaman Selama Kerja Praktik**
Kerja Praktik di PT. Pilar Timur Teknologi memberikan pengalaman langsung dalam mengikuti siklus pengembangan perangkat lunak, mulai dari pengembangan fitur, integrasi sistem, pengujian, hingga penyempurnaan aplikasi. Pengalaman baik yang dirasakan adalah tingginya tingkat kepercayaan yang diberikan oleh instansi kepada penulis untuk mengeksekusi fungsi-fungsi krusial layaknya pengembang profesional. 

Namun, ada kalanya penulis menghadapi kendala (*bottleneck*) dalam menyelaraskan dan mengintegrasikan kode antara *backend* dan *frontend* (*synchronization*) akibat asimetri format pada kontrak API. Pengalaman tersebut menjadi bekal berharga yang mengajarkan penulis tentang urgensi dokumentasi struktur data yang paten sebelum penulisan kode. Secara umum, pengalaman ini sangat mematangkan kompetensi teknis maupun profesional penulis sebagai persiapan memasuki dunia kerja di bidang teknologi informasi.

---
---

# BAB IV
# SIMPULAN DAN SARAN

## 4.1. Kesimpulan
Berdasarkan kegiatan kerja praktik yang telah penulis laksanakan di PT. Pilar Timur Teknologi (Digital Oasis), Bandung, maka dapat disimpulkan bahwa:
1. Selama masa kerja praktik, penulis berhasil memahami arsitektur dan alur kerja sistem IKA JTK secara menyeluruh, mencakup keterhubungan antara Backend API, CMS Admin Panel, dan Portal Alumni melalui RESTful API, serta berbagai modul fungsional sistem mencakup keanggotaan, portal karir, berita, agenda, E-Voting, dan Audit Log.
2. Penulis mampu memahami dan menerapkan teknologi yang digunakan dalam pengembangan sistem IKA JTK dengan berkontribusi langsung pada implementasi *client-side processing* untuk kompresi multimedia, integrasi data pemilu secara *real-time* melalui teknik *HTTP Polling*, serta penguatan ketahanan antarmuka pemrograman aplikasi (API) melalui *error masking*.
3. Penulis meningkatkan kemampuan teknis dalam pengembangan perangkat lunak berskala industri sekaligus mengembangkan kemampuan komunikasi, kolaborasi, dan manajemen waktu dalam lingkungan kerja profesional, sehingga mempersiapkan penulis untuk menghadapi dunia kerja di bidang teknologi informasi.

## 4.2. Saran
Berdasarkan pelaksanaan kegiatan kerja praktik di PT. Pilar Timur Teknologi (Digital Oasis), Bandung, terdapat beberapa saran yang dapat diberikan:

### 4.2.1. Saran untuk Perusahaan
Sistem IKA JTK yang dikembangkan telah berjalan dengan baik dan memiliki arsitektur yang terstruktur. Namun, akan lebih optimal apabila proses pengembangan di lingkungan kerja *agile* ini didukung oleh penetapan dokumentasi standar kontrak API secara terpusat (misalnya menggunakan *Swagger*). Hal ini penting untuk menekan potensi konflik sinkronisasi antar tim *backend* dan *frontend*. Selain itu, untuk proyek IKA JTK ke depannya, disarankan agar fitur pemantauan *real-time* dimigrasikan dari mekanisme *HTTP Polling* ke teknologi *WebSocket* guna menghadapi lonjakan trafik pada saat pemilihan umum secara lebih efisien dan ringan bagi peladen.

### 4.2.2. Saran untuk Pengembangan Ilmu Pengetahuan
Disarankan agar universitas dan program studi dapat menambahkan studi kasus nyata dari industri yang berkaitan dengan pengembangan web dan jaringan, khususnya mengenai perancangan API yang berorientasi pada keamanan siber (*safe error handling*). Selain itu, eksplorasi keilmuan terkait rekayasa prapemrosesan di sisi klien (*client-side processing*), seperti manipulasi data menggunakan *Canvas API* atau *WebGL*, sangat krusial untuk dimasukkan dalam kurikulum guna membantu mahasiswa/i lebih siap menghadapi tuntutan tren arsitektur *Single Page Application* (SPA) di dunia teknologi informasi modern.
