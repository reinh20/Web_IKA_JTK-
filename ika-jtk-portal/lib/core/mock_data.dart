class BeritaItem {
  final String id;
  final String judul;
  final String excerpt;
  final String tanggal;
  final String imageUrl;
  const BeritaItem({
    required this.id,
    required this.judul,
    required this.excerpt,
    required this.tanggal,
    required this.imageUrl,
  });
}

class AgendaItem {
  final String id;
  final int tanggal;
  final String bulan;
  final String tahun;
  final String judul;
  final String waktu;
  final String lokasi;
  final String deskripsi;
  const AgendaItem({
    required this.id,
    required this.tanggal,
    required this.bulan,
    required this.tahun,
    required this.judul,
    required this.waktu,
    required this.lokasi,
    required this.deskripsi,
  });
}

class FeatureItem {
  final String judul;
  final String deskripsi;
  final String iconKey;
  const FeatureItem({
    required this.judul,
    required this.deskripsi,
    required this.iconKey,
  });
}

class FaqItem {
  final String pertanyaan;
  final String jawaban;
  const FaqItem({required this.pertanyaan, required this.jawaban});
}

class HeroSlide {
  final String imageUrl;
  final String overlayTitle;
  final String badgeLabel;
  final String newsTitle;
  final String newsExcerpt;
  const HeroSlide({
    required this.imageUrl,
    required this.overlayTitle,
    required this.badgeLabel,
    required this.newsTitle,
    required this.newsExcerpt,
  });
}

class MockData {
  MockData._();

  static const heroSlides = [
    HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=1600&q=80',
      overlayTitle: 'REUNI AKBAR 2024!',
      badgeLabel: 'BERITA',
      newsTitle: 'Agenda Reuni Akbar 2025 Segera Hadir!',
      newsExcerpt:
          'Jangan lewatkan momen reuni akbar tahun ini. Catat tanggalnya dan ajak teman-teman alumni lainnya.',
    ),
    HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1600&q=80',
      overlayTitle: 'GATHERING ALUMNI',
      badgeLabel: 'EVENT',
      newsTitle: 'Networking Bersama Alumni Senior',
      newsExcerpt:
          'Manfaatkan kesempatan langka untuk berdiskusi langsung dengan para senior alumni di bidang masing-masing.',
    ),
    HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=1600&q=80',
      overlayTitle: 'INSPIRASI ALUMNI',
      badgeLabel: 'INSPIRASI',
      newsTitle: 'Kisah Sukses Alumni di Industri Teknologi',
      newsExcerpt:
          'Simak cerita inspiratif para alumni yang berkontribusi di berbagai perusahaan teknologi global.',
    ),
  ];

  static const featuredBerita = [
    BeritaItem(
      id: '1',
      judul: 'Alumni Teknik Komputer Polban Sukses Bangun Startup Teknologi',
      excerpt:
          'Rina, Angkatan 2010, berbagi cerita tentang perjalanan membangun startup teknologi yang kini berkembang pesat di Indonesia.',
      tanggal: '05 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=900&q=80',
    ),
    BeritaItem(
      id: '2',
      judul: 'Agenda Reuni Akbar 2025 Segera Hadir!',
      excerpt:
          'Jangan lewatkan momen reuni akbar tahun ini. Catat tanggalnya dan ajak teman-teman alumni lainnya.',
      tanggal: '05 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=900&q=80',
    ),
    BeritaItem(
      id: '3',
      judul: 'Lowongan Kerja Spesial Alumni di PT ABC Tech',
      excerpt:
          'Temukan kesempatan berkarier yang direkomendasikan langsung oleh alumni Teknik Komputer POLBAN.',
      tanggal: '05 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=900&q=80',
    ),
  ];

  static const beritaLainnya = [
    BeritaItem(
      id: '4',
      judul: 'Agenda Reuni Akbar 2025 Segera Hadir!',
      excerpt:
          'Jangan lewatkan momen reuni akbar tahun ini. Catat tanggalnya dan ajak teman-teman alumni lainnya.',
      tanggal: '05 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400&q=80',
    ),
    BeritaItem(
      id: '5',
      judul: 'Alumni Teknik Komputer Polban Sukses Bangun Startup Teknologi',
      excerpt:
          'Rina, Angkatan 2010, berbagi cerita tentang perjalanan membangun startup teknologi.',
      tanggal: '05 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=400&q=80',
    ),
    BeritaItem(
      id: '6',
      judul: 'Lowongan Kerja Spesial Alumni di PT ABC Tech',
      excerpt:
          'Temukan kesempatan berkarier yang direkomendasikan langsung oleh alumni Teknik Komputer POLBAN.',
      tanggal: '05 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=400&q=80',
    ),
    BeritaItem(
      id: '7',
      judul: 'Agenda Reuni Akbar 2025 Segera Hadir!',
      excerpt:
          'Jangan lewatkan momen reuni akbar tahun ini. Catat tanggalnya dan ajak teman-teman alumni lainnya.',
      tanggal: '05 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&q=80',
    ),
  ];

  static const agenda = [
    AgendaItem(
      id: '1',
      tanggal: 29,
      bulan: 'Jul',
      tahun: '2025',
      judul: 'Reuni Akbar 2025',
      waktu: '08.00 - 17.00',
      lokasi: 'POLBAN Bandung',
      deskripsi:
          'Satu hari penuh nostalgia, silaturahmi, dan networking alumni semua angkatan.',
    ),
    AgendaItem(
      id: '2',
      tanggal: 15,
      bulan: 'Jul',
      tahun: '2025',
      judul: 'Webinar Teknologi AI untuk Alumni',
      waktu: '19.00 - 21.00',
      lokasi: 'Online (Zoom)',
      deskripsi:
          'Diskusi terkini seputar AI bersama alumni yang bekerja di industri teknologi.',
    ),
    AgendaItem(
      id: '3',
      tanggal: 1,
      bulan: 'Agu',
      tahun: '2025',
      judul: 'Pemilu Ketua Alumni 2025',
      waktu: '09.00 - 16.00',
      lokasi: 'Aula POLBAN',
      deskripsi:
          'Berikan suara Anda untuk masa depan organisasi alumni kita!',
    ),
  ];

  static const features = [
    FeatureItem(
      judul: 'Jejaring Alumni',
      deskripsi: 'Bangun koneksi profesional lintas angkatan.',
      iconKey: 'network',
    ),
    FeatureItem(
      judul: 'Lowongan Kerja',
      deskripsi: 'Temukan peluang karier yang dibagikan alumni.',
      iconKey: 'briefcase',
    ),
    FeatureItem(
      judul: 'Agenda Alumni',
      deskripsi: 'Ikuti kegiatan alumni dan reuni.',
      iconKey: 'calendar',
    ),
    FeatureItem(
      judul: 'Galeri & Cerita',
      deskripsi: 'Momen bersama melalui foto dan testimoni alumni.',
      iconKey: 'photo',
    ),
  ];

  static const faqs = [
    FaqItem(
      pertanyaan: 'Bagaimana cara mendaftar akun?',
      jawaban:
          'Silakan klik Menu lalu pilih menu Register. Isi formulir yang diberikan lalu klik Daftar. Setelah itu Admin IKA JTK akan memverifikasi data Anda dan melakukan proses approval untuk kemudian user bisa login ke halaman Portal IKA JTK.',
    ),
    FaqItem(
      pertanyaan: 'Apa itu Sistem Informasi Alumni?',
      jawaban:
          'Sistem Informasi Alumni merupakan sebuah sistem dokumentasi Alumni. Disini kalian bisa mencari alumni, event dan kegiatan alumni serta informasi kerjasama dan informasi lainnya.',
    ),
    FaqItem(
      pertanyaan: 'Bagaimana cara melihat profil IKA JTK?',
      jawaban:
          'Anda bisa register terlebih dahulu, kemudian login ke Portal IKA JTK dan pilih menu List Member IKA JTK.',
    ),
    FaqItem(
      pertanyaan: 'Bagaimana cara saya mengedit data yang salah?',
      jawaban:
          'Silakan Anda login menggunakan akun aktif Anda di Portal IKA JTK lalu klik Update My Profile.',
    ),
    FaqItem(
      pertanyaan: 'Saya tidak ingin data saya ada disini!',
      jawaban:
          'Silakan hubungi Admin IKA JTK di pengurus@ikajtk.id untuk menghapus akun Anda dari sistem database kami.',
    ),
  ];
}
