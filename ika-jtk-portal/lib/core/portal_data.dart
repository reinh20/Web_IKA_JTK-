/// Centralized mock data for portal pages (berita, agenda, loker, alumni directory,
/// notifications, voting). Replace with real API later.
library;

import 'dart:convert';
import 'format_utils.dart';

class HighlightedAlumni {
  final String id;
  final String nama;
  final String angkatan;
  final String avatarUrl;

  const HighlightedAlumni({
    required this.id,
    required this.nama,
    required this.angkatan,
    required this.avatarUrl,
  });
}

class BeritaContent {
  final String id;
  final String judul;
  final String excerpt;
  final String konten;
  final String tanggal;
  final String imageUrl;
  final String fullImageUrl;
  final String kategori;
  final String authorId;
  final String authorNama;
  final String authorRole;
  final String authorAvatarUrl;
  final HighlightedAlumni? highlightedAlumni;
  final String tags;

  const BeritaContent({
    required this.id,
    required this.judul,
    required this.excerpt,
    required this.konten,
    required this.tanggal,
    required this.imageUrl,
    this.fullImageUrl = '',
    required this.kategori,
    this.authorId = '',
    required this.authorNama,
    this.authorRole = '',
    required this.authorAvatarUrl,
    this.highlightedAlumni,
    this.tags = '',
  });
}

class AgendaContent {
  final String id;
  final int tanggal;
  final String bulan;
  final String tahun;
  final String judul;
  final String deskripsi;
  final String waktu;
  final String lokasi;
  final String imageUrl;
  final String fullImageUrl;
  final String authorNama;
  final String authorRole;
  final String authorAvatarUrl;
  final String publishedAt;
  final String tanggalEventRaw;
  final String tags;

  const AgendaContent({
    required this.id,
    required this.tanggal,
    required this.bulan,
    required this.tahun,
    required this.judul,
    required this.deskripsi,
    required this.waktu,
    required this.lokasi,
    required this.imageUrl,
    this.fullImageUrl = '',
    this.authorNama = '',
    this.authorRole = '',
    this.authorAvatarUrl = '',
    this.publishedAt = '',
    this.tanggalEventRaw = '',
    this.tags = '',
  });
}

class LokerContent {
  final String id;
  final String posisi;
  final String namaPerusahaan;
  final String websitePerusahaan;
  final String logoUrl;
  final String fullLogoUrl;
  final String jenisPekerjaan;
  final String tipeLokasi;
  final String kota;
  final String deskripsi;
  final String skemaPelamaran;
  final String linkExternal;
  final List<FormLamaranField> formLamaran;
  final String dipostingTanggal;
  final String createdAtRaw;
  final String authorNama;
  final String authorRole;
  final String authorAvatarUrl;
  final String tags;

  const LokerContent({
    required this.id,
    required this.posisi,
    required this.namaPerusahaan,
    this.websitePerusahaan = '',
    required this.logoUrl,
    this.fullLogoUrl = '',
    required this.jenisPekerjaan,
    required this.tipeLokasi,
    required this.kota,
    required this.deskripsi,
    this.skemaPelamaran = 'internal',
    this.linkExternal = '',
    this.formLamaran = const [],
    required this.dipostingTanggal,
    this.createdAtRaw = '',
    this.authorNama = '',
    this.authorRole = '',
    this.authorAvatarUrl = '',
    this.tags = '',
  });
}


class FormLamaranField {
  final String id;
  final String label;
  final String tipe;
  final List<String>? options;
  final bool? required;
  final String? defaultValue;
  final String? fileUrl;
  final String? fileName;

  FormLamaranField({
    required this.id,
    required this.label,
    required this.tipe,
    this.options,
    this.required,
    this.defaultValue,
    this.fileUrl,
    this.fileName,
  });

  factory FormLamaranField.fromJson(Map<String, dynamic> json) {
    return FormLamaranField(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      tipe: json['tipe'] ?? 'text',
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      required: json['required'] as bool?,
      defaultValue: json['defaultValue']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
    );
  }
}

class AlumniDirEntry {
  final String id;
  final String? noAlumni;
  final String nama;
  final int? angkatan;
  final String fotoUrl;
  final String posisiSekarang;
  final String perusahaan;
  final String keanggotaan;
  final Map<String, dynamic>? alumniGrafis;

  const AlumniDirEntry({
    this.id = '',
    this.noAlumni,
    this.nama = '',
    this.angkatan,
    this.fotoUrl = '',
    this.posisiSekarang = '',
    this.perusahaan = '',
    this.keanggotaan = 'Alumni',
    this.alumniGrafis,
  });

  factory AlumniDirEntry.fromJson(Map<String, dynamic> json) {
    return AlumniDirEntry(
      id: json['id']?.toString() ?? '',
      noAlumni: json['noAlumni']?.toString(),
      nama: json['nama']?.toString() ?? '',
      angkatan: json['angkatan'] != null ? int.tryParse(json['angkatan'].toString()) : null,
      fotoUrl: resolveThumbnailUrl(json['avatarUrl']?.toString() ?? json['fotoUrl']?.toString(), fallbackName: json['nama']?.toString()),
      posisiSekarang: json['posisiSekarang']?.toString() ?? '',
      perusahaan: json['perusahaan']?.toString() ?? '',
      keanggotaan: json['keanggotaan']?.toString() ?? 'Alumni',
      alumniGrafis: json['alumniGrafis'],
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String tanggal;
  final String tipe;
  final bool read;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.tanggal,
    required this.tipe,
    required this.read,
  });
}

class ProgramKerjaItem {
  final String title;
  final String description;

  const ProgramKerjaItem({required this.title, required this.description});

  factory ProgramKerjaItem.fromJson(dynamic json) {
    if (json is Map) {
      return ProgramKerjaItem(
        title: (json['title'] ?? json['judul'] ?? '').toString(),
        description: (json['description'] ?? json['deskripsi'] ?? '').toString(),
      );
    }
    if (json is String) {
      return ProgramKerjaItem(title: json, description: '');
    }
    return const ProgramKerjaItem(title: '', description: '');
  }
}

class PrestasiItem {
  final String text;
  final String year;

  const PrestasiItem({required this.text, required this.year});

  factory PrestasiItem.fromJson(dynamic json) {
    if (json is Map) {
      return PrestasiItem(
        text: (json['text'] ?? json['judul'] ?? '').toString(),
        year: (json['year'] ?? json['tahun'] ?? '').toString(),
      );
    }
    if (json is String) {
      return PrestasiItem(text: json, year: '');
    }
    return const PrestasiItem(text: '', year: '');
  }
}

class Candidate {
  final String id;
  /// ID alumni yang menjadi kandidat (untuk navigasi ke profil alumni)
  final String? alumniId;
  final String nama;
  final int? angkatan;
  final String fotoUrl;
  final String visi;
  final List<String> misi;
  final List<String> pengalaman;
  final List<ProgramKerjaItem> programKerja;
  final List<PrestasiItem> prestasi;
  final String tagline;
  final int voteCount;
  final int nomorUrut;

  const Candidate({
    required this.id,
    this.alumniId,
    required this.nama,
    required this.angkatan,
    required this.fotoUrl,
    required this.visi,
    required this.misi,
    required this.pengalaman,
    this.programKerja = const [],
    this.prestasi = const [],
    this.tagline = '',
    required this.voteCount,
    required this.nomorUrut,
  });

  factory Candidate.fromApiJson(Map<String, dynamic> json) {
    String cleanHtml(String text) {
      return text
          .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    List<String> parseList(dynamic value) {
      if (value is List) {
        return value.map((e) => cleanHtml(e.toString())).where((e) => e.isNotEmpty).toList();
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => cleanHtml(e.toString())).where((e) => e.isNotEmpty).toList();
          }
        } catch (_) {}
      }
      return [];
    }

    List<ProgramKerjaItem> parseProgramKerja(dynamic value) {
      if (value is Map && value['programKerja'] is List) {
        return (value['programKerja'] as List).map((e) => ProgramKerjaItem.fromJson(e)).toList();
      }
      if (value is List) {
        return value.map((e) => ProgramKerjaItem.fromJson(e)).toList();
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map && decoded['programKerja'] is List) {
            return (decoded['programKerja'] as List).map((e) => ProgramKerjaItem.fromJson(e)).toList();
          }
          if (decoded is List) {
            return decoded.map((e) => ProgramKerjaItem.fromJson(e)).toList();
          }
        } catch (_) {}
      }
      return [];
    }

    List<PrestasiItem> parsePrestasi(dynamic value) {
      if (value is Map && value['prestasi'] is List) {
        return (value['prestasi'] as List).map((e) => PrestasiItem.fromJson(e)).toList();
      }
      if (value is List) {
        return value.map((e) => PrestasiItem.fromJson(e)).toList();
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map && decoded['prestasi'] is List) {
            return (decoded['prestasi'] as List).map((e) => PrestasiItem.fromJson(e)).toList();
          }
          if (decoded is List) {
            return decoded.map((e) => PrestasiItem.fromJson(e)).toList();
          }
        } catch (_) {}
      }
      return [];
    }

    final rawPengalaman = json['pengalaman'];
    final rawProgramKerja = json['programKerja'];
    final rawPrestasi = json['prestasi'];

    final programKerjaSource = rawProgramKerja ??
        (rawPengalaman is Map ? rawPengalaman['programKerja'] : null);
    final prestasiSource = rawPrestasi ??
        (rawPengalaman is Map ? rawPengalaman['prestasi'] : null);
    final pengalamanSource =
        rawPengalaman is Map ? rawPengalaman['list'] : rawPengalaman;

    final programKerjaList = parseProgramKerja(programKerjaSource)
        .where((p) => p.title.isNotEmpty || p.description.isNotEmpty)
        .toList();

    final prestasiList = parsePrestasi(prestasiSource)
        .where((p) => p.text.isNotEmpty)
        .toList();

    int? parseAngkatan(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return Candidate(
      id: json['id']?.toString() ?? '',
      alumniId: json['alumniId']?.toString(),
      nama: json['nama']?.toString() ?? '',
      angkatan: parseAngkatan(json['angkatan']),
      fotoUrl: resolveImageUrl(json['fotoUrl']?.toString(), fallbackName: json['nama']?.toString()),
      visi: json['visi']?.toString() ?? '',
      misi: parseList(json['misi']),
      pengalaman: parseList(pengalamanSource),
      programKerja: programKerjaList,
      prestasi: prestasiList,
      tagline: (json['tagline']?.toString() ?? '').trim(),
      voteCount: json['voteCount'] is int
          ? json['voteCount'] as int
          : int.tryParse(json['voteCount']?.toString() ?? '0') ?? 0,
      nomorUrut: json['nomorUrut'] is int
          ? json['nomorUrut'] as int
          : int.tryParse(json['nomorUrut']?.toString() ?? '1') ?? 1,
    );
  }
}

class LamaranEntry {
  final String id;
  final String lokerId;
  final String posisi;
  final String perusahaan;
  final String logoUrl;
  final String status;
  final String dilamarPada;

  const LamaranEntry({
    required this.id,
    required this.lokerId,
    required this.posisi,
    required this.perusahaan,
    required this.logoUrl,
    required this.status,
    required this.dilamarPada,
  });
}

const _ARTIKEL = '''Salah satu alumni Jurusan Teknik Komputer Politeknik Negeri Bandung berhasil mencatatkan prestasi luar biasa dengan mendirikan sebuah startup teknologi yang kini telah berkembang pesat di bidang solusi digital. Startup tersebut berfokus pada pengembangan platform berbasis Artificial Intelligence yang membantu perusahaan dalam proses transformasi digital.

Alumni bernama Arif Pratama (angkatan 2010) ini, bersama timnya yang sebagian besar juga merupakan alumni JTK, memulai usaha tersebut pada tahun 2022. Berkat kegigihan dan inovasi yang terus dilakukan, mereka berhasil mendapatkan pendanaan seri A sebesar 15 miliar rupiah dari investor lokal dan internasional.

Dalam wawancara bersama tim redaksi IKA JTK, Arif mengungkapkan bahwa latar belakang pendidikan di Teknik Komputer Polban sangat membantunya dalam memahami teknologi, mengembangkan produk, dan memimpin tim yang solid.

"Jangan takut untuk memulai, karena kita punya jaringan alumni yang luar biasa untuk saling membantu dan berkembang," ujarnya penuh semangat.''';

const _LOKER_DESC = '''Biffco Enterprises Ltd. membuka kesempatan bagi profesional berpengalaman untuk bergabung sebagai Software Development Manager.

📍 Tanggung Jawab
- Memimpin dan mengelola tim software engineer dalam proyek pengembangan end-to-end
- Menyusun arsitektur sistem dan menyupervisi penerapan best practice coding
- Berkoordinasi dengan tim lintas fungsi seperti Product, QA, dan DevOps
- Mengawasi timeline, anggaran, dan kualitas dari setiap fase proyek

🎓 Kualifikasi
- Lulusan S1/D4 Teknik Komputer, Informatika, atau bidang terkait
- Pengalaman minimal 5 tahun di bidang software development
- Menguasai teknologi backend/frontend modern (Node.js, React, Java, dsb)
- Memiliki pengalaman dengan metode Agile/Scrum

💎 Nilai Tambah
- Pengalaman di industri manufaktur atau logistik
- Sertifikasi Project Management (PMP, Scrum Master, dsb)

🕐 Jam Kerja & Benefit
- Senin–Jumat, 09.00-17.00 (WIB)
- Gaji kompetitif, tunjangan kesehatan, pelatihan profesional, dan jenjang karier yang jelas''';

class PortalData {
  PortalData._();

  static List<BeritaContent> get berita => [
    BeritaContent(
      id: 'b1',
      judul: 'Alumni Teknik Komputer Polban Sukses Bangun Startup Teknologi',
      excerpt:
          'Rina, Angkatan 2010, berbagi cerita tentang perjalanan membangun startup teknologi yang kini berkembang pesat di Indonesia.',
      konten: _ARTIKEL,
      tanggal: '05 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=1200&q=80',
      kategori: 'Inspirasi',
      authorNama: 'Tim Redaksi',
      authorAvatarUrl: 'https://i.pravatar.cc/100?u=tim-redaksi',
    ),
    BeritaContent(
      id: 'b2',
      judul: 'Agenda Reuni Akbar 2025 Segera Hadir!',
      excerpt:
          'Jangan lewatkan momen reuni akbar tahun ini. Catat tanggalnya dan ajak teman-teman alumni lainnya.',
      konten: _ARTIKEL,
      tanggal: '03 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=1200&q=80',
      kategori: 'Event',
      authorNama: 'Panitia Reuni',
      authorAvatarUrl: 'https://i.pravatar.cc/100?u=panitia',
    ),
    BeritaContent(
      id: 'b3',
      judul: 'Lowongan Kerja Spesial Alumni di PT ABC Tech',
      excerpt:
          'Temukan kesempatan berkarier yang direkomendasikan langsung oleh alumni Teknik Komputer POLBAN.',
      konten: _ARTIKEL,
      tanggal: '01 Jun 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=1200&q=80',
      kategori: 'Karier',
      authorNama: 'HR ABC Tech',
      authorAvatarUrl: 'https://i.pravatar.cc/100?u=hr-abc',
    ),
    BeritaContent(
      id: 'b4',
      judul: 'Workshop AI untuk Alumni Berlangsung Meriah',
      excerpt:
          'Lebih dari 200 alumni hadir dalam workshop kecerdasan buatan yang diselenggarakan bulan ini.',
      konten: _ARTIKEL,
      tanggal: '28 Mei 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=1200&q=80',
      kategori: 'Event',
      authorNama: 'Tim Redaksi',
      authorAvatarUrl: 'https://i.pravatar.cc/100?u=tim-redaksi',
    ),
    BeritaContent(
      id: 'b5',
      judul: 'Alumni Mengabdi: Bersama Membangun Desa Digital',
      excerpt:
          'Program pengabdian alumni ke desa-desa berhasil menyentuh kehidupan 500+ warga.',
      konten: _ARTIKEL,
      tanggal: '20 Mei 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&q=80',
      kategori: 'Pengabdian',
      authorNama: 'Komunitas IKAJTK',
      authorAvatarUrl: 'https://i.pravatar.cc/100?u=komunitas',
    ),
    BeritaContent(
      id: 'b6',
      judul: 'Beasiswa Khusus Anak Alumni Kembali Dibuka',
      excerpt:
          'Pendaftaran beasiswa pendidikan untuk anak-anak alumni telah dibuka mulai bulan ini.',
      konten: _ARTIKEL,
      tanggal: '15 Mei 2025',
      imageUrl:
          'https://images.unsplash.com/photo-1523580494863-6f3031224c94?w=1200&q=80',
      kategori: 'Pengumuman',
      authorNama: 'Pengurus IKA JTK',
      authorAvatarUrl: 'https://i.pravatar.cc/100?u=pengurus',
    ),
  ];

  static List<AgendaContent> get agenda => [
    AgendaContent(
      id: 'a1',
      tanggal: 29,
      bulan: 'Jul',
      tahun: '2025',
      judul: 'Reuni Akbar 2025',
      deskripsi:
          'Hari penuh nostalgia, silaturahmi, dan networking alumni IKA JTK Polban dari semua angkatan. Acara meliputi sharing alumni sukses, talkshow, pameran teknologi, dan hiburan band alumni.',
      waktu: '08.00 - 17.00 WIB',
      lokasi: 'Kampus Politeknik Negeri Bandung (Aula Utama)',
      imageUrl:
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=1200&q=80',
    ),
    AgendaContent(
      id: 'a2',
      tanggal: 15,
      bulan: 'Jul',
      tahun: '2025',
      judul: 'Webinar Teknologi AI untuk Alumni',
      deskripsi:
          'Diskusi terkini seputar AI bersama alumni yang bekerja di industri teknologi. Gratis dan terbuka untuk seluruh alumni.',
      waktu: '19.00 - 21.00 WIB',
      lokasi: 'Online (Zoom)',
      imageUrl:
          'https://images.unsplash.com/photo-1531058020387-3be344556be6?w=1200&q=80',
    ),
    AgendaContent(
      id: 'a3',
      tanggal: 1,
      bulan: 'Agu',
      tahun: '2025',
      judul: 'Pemilu Ketua Alumni',
      deskripsi:
          'Berikan suara Anda untuk masa depan organisasi alumni kita. Tersedia kandidat terbaik untuk menjadi ketua periode kepengurusan selanjutnya.',
      waktu: '09.00 - 16.00 WIB',
      lokasi: 'Aula Politeknik Negeri Bandung',
      imageUrl:
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200&q=80',
    ),
    AgendaContent(
      id: 'a4',
      tanggal: 12,
      bulan: 'Jun',
      tahun: '2025',
      judul: 'Mentor Day - Karier Lintas Generasi',
      deskripsi:
          'Sesi mentoring 1-on-1 antara alumni senior dan alumni muda yang ingin meningkatkan karier mereka.',
      waktu: '13.00 - 17.00 WIB',
      lokasi: 'Co-working Space, Bandung',
      imageUrl:
          'https://images.unsplash.com/photo-1556761175-b413da4baf72?w=1200&q=80',
    ),
    AgendaContent(
      id: 'a5',
      tanggal: 5,
      bulan: 'Jun',
      tahun: '2025',
      judul: 'Open House Inovasi Alumni',
      deskripsi:
          'Pameran produk dan startup alumni IKA JTK. Open untuk publik dan calon investor.',
      waktu: '10.00 - 18.00 WIB',
      lokasi: 'Gedung Inkubasi POLBAN',
      imageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200&q=80',
    ),
  ];

  static List<LokerContent> get loker => [
    LokerContent(
      id: 'l1',
      posisi: 'Software Development Manager',
      namaPerusahaan: 'Biffco Enterprises Ltd.',
      logoUrl: 'https://i.pravatar.cc/120?u=biffco',
      jenisPekerjaan: 'Full Time',
      tipeLokasi: 'Onsite',
      kota: 'Malang',
      deskripsi: _LOKER_DESC,
      skemaPelamaran: 'internal',
      dipostingTanggal: '20 Jun 2025',
    ),
    LokerContent(
      id: 'l2',
      posisi: 'Frontend Engineer',
      namaPerusahaan: 'Astra Digital',
      logoUrl: 'https://i.pravatar.cc/120?u=astra',
      jenisPekerjaan: 'Full Time',
      tipeLokasi: 'Hybrid',
      kota: 'Jakarta Selatan',
      deskripsi: _LOKER_DESC,
      skemaPelamaran: 'internal',
      dipostingTanggal: '18 Jun 2025',
    ),
    LokerContent(
      id: 'l3',
      posisi: 'UI/UX Designer',
      namaPerusahaan: 'Binford Ltd.',
      logoUrl: 'https://i.pravatar.cc/120?u=binford',
      jenisPekerjaan: 'Kontrak',
      tipeLokasi: 'Remote',
      kota: 'Bandung',
      deskripsi: _LOKER_DESC,
      skemaPelamaran: 'external',
      linkExternal: 'https://career.binford.com/apply',
      dipostingTanggal: '15 Jun 2025',
    ),
    LokerContent(
      id: 'l4',
      posisi: 'Backend Engineer (Go)',
      namaPerusahaan: 'Acme Co.',
      logoUrl: 'https://i.pravatar.cc/120?u=acme',
      jenisPekerjaan: 'Full Time',
      tipeLokasi: 'Onsite',
      kota: 'Yogyakarta',
      deskripsi: _LOKER_DESC,
      skemaPelamaran: 'internal',
      dipostingTanggal: '12 Jun 2025',
    ),
    LokerContent(
      id: 'l5',
      posisi: 'Data Engineer',
      namaPerusahaan: 'Abstergo Ltd.',
      logoUrl: 'https://i.pravatar.cc/120?u=abstergo',
      jenisPekerjaan: 'Full Time',
      tipeLokasi: 'Hybrid',
      kota: 'Surabaya',
      deskripsi: _LOKER_DESC,
      skemaPelamaran: 'internal',
      dipostingTanggal: '10 Jun 2025',
    ),
    LokerContent(
      id: 'l6',
      posisi: 'Product Manager',
      namaPerusahaan: 'Barone LLC.',
      logoUrl: 'https://i.pravatar.cc/120?u=barone',
      jenisPekerjaan: 'Full Time',
      tipeLokasi: 'Onsite',
      kota: 'Jakarta Selatan',
      deskripsi: _LOKER_DESC,
      skemaPelamaran: 'external',
      linkExternal: 'https://career.barone.com/pm',
      dipostingTanggal: '08 Jun 2025',
    ),
  ];

  static List<AlumniDirEntry> get alumniDirectory => [
    AlumniDirEntry(
      id: 'c1',
      nama: 'Rina Aulia Putri',
      angkatan: 2008,
      fotoUrl: 'https://i.pravatar.cc/400?u=rina-aulia-putri-kandidat',
      posisiSekarang: 'Senior VP Engineering',
      perusahaan: 'PT Teknologi',
    ),
    AlumniDirEntry(
      id: 'c2',
      nama: 'Bagus Setiawan',
      angkatan: 2011,
      fotoUrl: 'https://i.pravatar.cc/400?u=bagus-setiawan-kandidat',
      posisiSekarang: 'Head of Product',
      perusahaan: 'Gojek',
    ),
    AlumniDirEntry(
      id: 'c3',
      nama: 'Siti Nurhaliza',
      angkatan: 2014,
      fotoUrl: 'https://i.pravatar.cc/400?u=siti-nurhaliza-kandidat',
      posisiSekarang: 'AI Research Lead',
      perusahaan: 'Bukalapak',
    ),
    AlumniDirEntry(
      id: 'ad1',
      nama: 'Sari Rahmawati',
      angkatan: 2012,
      fotoUrl: 'https://i.pravatar.cc/300?u=sari-rahmawati-dir',
      posisiSekarang: 'Sr. Backend Engineer',
      perusahaan: 'PT Teknologi',
    ),
    AlumniDirEntry(
      id: 'ad2',
      nama: 'Ivan William',
      angkatan: 2018,
      fotoUrl: 'https://i.pravatar.cc/300?u=ivan-william',
      posisiSekarang: 'Software Engineer',
      perusahaan: 'Tokopedia',
    ),
    AlumniDirEntry(
      id: 'ad3',
      nama: 'Bagas Pramudita',
      angkatan: 2020,
      fotoUrl: 'https://i.pravatar.cc/300?u=bagas-pramudita',
      posisiSekarang: 'Mobile Developer',
      perusahaan: 'Gojek',
    ),
    AlumniDirEntry(
      id: 'ad4',
      nama: 'Dewi Lestari',
      angkatan: 2015,
      fotoUrl: 'https://i.pravatar.cc/300?u=dewi-lestari',
      posisiSekarang: 'Product Designer',
      perusahaan: 'Traveloka',
    ),
    AlumniDirEntry(
      id: 'ad5',
      nama: 'Eko Prasetyo',
      angkatan: 2010,
      fotoUrl: 'https://i.pravatar.cc/300?u=eko-prasetyo',
      posisiSekarang: 'CTO',
      perusahaan: 'NusaTech',
    ),
    AlumniDirEntry(
      id: 'ad6',
      nama: 'Yulia Andayani',
      angkatan: 2019,
      fotoUrl: 'https://i.pravatar.cc/300?u=yulia-andayani',
      posisiSekarang: 'Data Scientist',
      perusahaan: 'Bukalapak',
    ),
    AlumniDirEntry(
      id: 'ad7',
      nama: 'Andi Saputra',
      angkatan: 2014,
      fotoUrl: 'https://i.pravatar.cc/300?u=andi-saputra',
      posisiSekarang: 'Engineering Manager',
      perusahaan: 'Shopee',
    ),
    AlumniDirEntry(
      id: 'ad8',
      nama: 'Rina Marlina',
      angkatan: 2016,
      fotoUrl: 'https://i.pravatar.cc/300?u=rina-marlina',
      posisiSekarang: 'DevOps Lead',
      perusahaan: 'Blibli',
    ),
    AlumniDirEntry(
      id: 'ad9',
      nama: 'Fajar Nugraha',
      angkatan: 2017,
      fotoUrl: 'https://i.pravatar.cc/300?u=fajar-nugraha',
      posisiSekarang: 'Security Engineer',
      perusahaan: 'Bank Mandiri',
    ),
    AlumniDirEntry(
      id: 'ad10',
      nama: 'Nadia Hapsari',
      angkatan: 2021,
      fotoUrl: 'https://i.pravatar.cc/300?u=nadia-hapsari',
      posisiSekarang: 'UI Designer',
      perusahaan: 'Tiket.com',
    ),
    AlumniDirEntry(
      id: 'ad11',
      nama: 'Hendra Wijaya',
      angkatan: 2013,
      fotoUrl: 'https://i.pravatar.cc/300?u=hendra-wijaya',
      posisiSekarang: 'Senior Architect',
      perusahaan: 'Telkom Indonesia',
    ),
    AlumniDirEntry(
      id: 'ad12',
      nama: 'Joko Darwono',
      angkatan: 1998,
      fotoUrl: 'https://i.pravatar.cc/300?u=joko-darwono',
      posisiSekarang: 'CEO',
      perusahaan: 'Founder of SintaTech',
    ),
  ];

  static AlumniDirEntry get featuredAlumni => alumniDirectory.first;

  static List<NotificationItem> get notifications => [
    NotificationItem(
      id: 'n1',
      title: 'Berita baru diterbitkan',
      body: 'Alumni Teknik Komputer Polban Sukses Bangun Startup Teknologi',
      tanggal: '05 Jun 2025, 10:24',
      tipe: 'berita',
      read: false,
    ),
    NotificationItem(
      id: 'n2',
      title: 'Lamaran Anda diterima review',
      body: 'PT Teknologi telah menerima lamaran Anda untuk posisi Software Development Manager',
      tanggal: '03 Jun 2025, 14:11',
      tipe: 'lamaran',
      read: false,
    ),
    NotificationItem(
      id: 'n3',
      title: 'Pengingat acara: Reuni Akbar 2025',
      body: 'Reuni Akbar 2025 akan diselenggarakan 29 Jul 2025. Catat di kalender Anda!',
      tanggal: '02 Jun 2025, 09:00',
      tipe: 'agenda',
      read: true,
    ),
    NotificationItem(
      id: 'n4',
      title: 'PEMILU Ketua Alumni dimulai',
      body: 'Voting kandidat ketua alumni untuk periode kepengurusan baru telah dibuka. Berikan suara Anda!',
      tanggal: '01 Jun 2025, 08:00',
      tipe: 'pemilu',
      read: true,
    ),
    NotificationItem(
      id: 'n5',
      title: 'Profile Anda diperbarui',
      body: 'Data profil Anda berhasil diperbarui oleh admin IKA JTK',
      tanggal: '29 Mei 2025, 16:45',
      tipe: 'profile',
      read: true,
    ),
  ];

  static List<Candidate> get candidates => [
    Candidate(
      id: 'c1',
      nama: 'Rina Aulia Putri',
      angkatan: 2008,
      fotoUrl: 'https://i.pravatar.cc/400?u=rina-aulia-putri-kandidat',
      visi: 'Membangun ekosistem alumni IKA JTK yang inklusif, kolaboratif, dan berdampak nyata bagi masyarakat.',
      misi: [
        'Memperluas jejaring alumni lintas industri dan generasi',
        'Mendorong program mentorship dan beasiswa pendidikan',
        'Membangun platform digital terintegrasi untuk seluruh aktivitas alumni',
        'Memperkuat kontribusi alumni kepada Polban dan masyarakat',
      ],
      pengalaman: [
        'Senior VP Engineering di PT Teknologi (2020-sekarang)',
        'Co-founder NusaTech Inkubator (2018)',
        'Ketua Asosiasi Alumni Wanita Tech Indonesia (2016-2020)',
      ],
      programKerja: [
        ProgramKerjaItem(title:'Digital Alumni Hub', description: 'Satu portal untuk data alumni, kegiatan, lowongan, mentoring, dan pemilu.'),
        ProgramKerjaItem(title:'Program Mentorship Alumni', description: 'Menghubungkan alumni senior dengan junior.'),
        ProgramKerjaItem(title:'Forum Alumni Wilayah', description: 'Komunitas alumni aktif di kota besar.'),
        ProgramKerjaItem(title:'Kolaborasi dengan Kampus', description: 'Seminar, beasiswa, dan pelatihan rutin'),
      ],
      prestasi: [
        PrestasiItem(text:'Top 50 Inspiring Women in Tech – SWA Magazine 2023', year: '2023'),
        PrestasiItem(text:'Founder “NusaTech”, inkubator startup berbasis alumni', year: '2020'),
        PrestasiItem(text:'Digital Product Mentor di Kementerian Kominfo RI', year: '2019'),
      ],
      voteCount: 1247,
      nomorUrut: 1,
    ),
    Candidate(
      id: 'c2',
      nama: 'Bagus Setiawan',
      angkatan: 2005,
      fotoUrl: 'https://i.pravatar.cc/400?u=bagus-setiawan-kandidat',
      visi: 'IKA JTK sebagai jembatan inovasi antara akademisi, industri, dan alumni untuk Indonesia maju.',
      misi: [
        'Mendorong kolaborasi industri-akademisi melalui alumni',
        'Mengembangkan inkubator startup berbasis alumni',
        'Membentuk pusat data karier alumni',
        'Memperkuat program CSR alumni untuk pendidikan',
      ],
      pengalaman: [
        'CTO PT Inovasi Digital (2019-sekarang)',
        'Konsultan IT untuk Kementerian Pendidikan (2017-2019)',
        'Founder Komunitas Startup Bandung (2015)',
      ],
      programKerja: [
        ProgramKerjaItem(title:'Inkubator Bisnis Alumni', description: 'Fasilitas pendanaan dan mentoring untuk usaha rintisan alumni JTK.'),
        ProgramKerjaItem(title:'Kemitraan Industri Strategis', description: 'Kerjasama langsung dengan perusahaan teknologi untuk penyaluran kerja.'),
        ProgramKerjaItem(title:'Dana Abadi Pendidikan', description: 'Pengelolaan dana bantuan dan beasiswa bagi mahasiswa aktif Polban.'),
      ],
      prestasi: [
        PrestasiItem(text:'Tokoh Transformasi Digital Jawa Barat', year: '2022'),
        PrestasiItem(text:'Juara 1 Hackathon Nasional Kemenkominfo', year: '2018'),
      ],
      voteCount: 893,
      nomorUrut: 2,
    ),
    Candidate(
      id: 'c3',
      nama: 'Siti Aminah',
      angkatan: 2010,
      fotoUrl: 'https://i.pravatar.cc/400?u=siti-aminah-kandidat',
      visi: 'Memberdayakan generasi muda alumni untuk berkontribusi dalam transformasi digital nasional.',
      misi: [
        'Program akselerasi karier untuk alumni muda',
        'Membangun database alumni terintegrasi nasional',
        'Memperluas kemitraan strategis dengan industri',
        'Memperkuat budaya saling membantu antar alumni',
      ],
      pengalaman: [
        'Head of Engineering di Gojek (2021-sekarang)',
        'Tech Lead di Tokopedia (2017-2021)',
        'Mentor di berbagai program pelatihan teknologi',
      ],
      programKerja: [
        ProgramKerjaItem(title:'JTK Career Booster', description: 'Pelatihan intensif persiapan karier dan wawancara bagi fresh graduate.'),
        ProgramKerjaItem(title:'Global Alumni Network', description: 'Penghubung jejaring alumni JTK yang berkarier di luar negeri.'),
        ProgramKerjaItem(title:'Portal Riset & Inovasi', description: 'Wadah kolaborasi karya ilmiah dan proyek open-source alumni.'),
      ],
      prestasi: [
        PrestasiItem(text:'Best Engineering Leader di Tech Asia Awards', year: '2023'),
        PrestasiItem(text:'Speaker Utama di Southeast Asia Developer Summit', year: '2021'),
      ],
      voteCount: 654,
      nomorUrut: 3,
    ),
  ];

  static List<LamaranEntry> get lamaranSaya => [
    LamaranEntry(
      id: 'la1',
      lokerId: 'l1',
      posisi: 'Software Development Manager',
      perusahaan: 'Biffco Enterprises Ltd.',
      logoUrl: 'https://i.pravatar.cc/120?u=biffco',
      status: 'Sedang Direview',
      dilamarPada: '05 Jun 2025',
    ),
    LamaranEntry(
      id: 'la2',
      lokerId: 'l2',
      posisi: 'Frontend Engineer',
      perusahaan: 'Astra Digital',
      logoUrl: 'https://i.pravatar.cc/120?u=astra',
      status: 'Diterima',
      dilamarPada: '02 Jun 2025',
    ),
    LamaranEntry(
      id: 'la3',
      lokerId: 'l4',
      posisi: 'Backend Engineer (Go)',
      perusahaan: 'Acme Co.',
      logoUrl: 'https://i.pravatar.cc/120?u=acme',
      status: 'Ditolak',
      dilamarPada: '29 Mei 2025',
    ),
  ];

  static String get votingDeadline => '01 Agu 2025, 16:00 WIB';
  static int get votingTotal => 2794;
}
