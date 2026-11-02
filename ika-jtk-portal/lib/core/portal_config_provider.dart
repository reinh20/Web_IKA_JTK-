import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';

/// Strips HTML tags and common entities from rich-text content saved by the
/// CMS editor (which stores HTML), so the portal can render it as plain text.
String stripHtml(String html) {
  if (html.isEmpty) return html;

  String processed = html;

  processed = processed.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  processed = processed.replaceAll(RegExp(r'</(p|div|h[1-6]|tr)>', caseSensitive: false), '\n\n');

  processed = processed.replaceAllMapped(
    RegExp(r'<ol[^>]*>(.*?)</ol>', caseSensitive: false, dotAll: true),
    (match) {
      final listContent = match.group(1) ?? '';
      int counter = 1;
      final itemsFormatted = listContent.replaceAllMapped(
        RegExp(r'<li[^>]*>(.*?)</li>', caseSensitive: false, dotAll: true),
        (liMatch) {
          final itemText = liMatch.group(1) ?? '';
          return '  ${counter++}. $itemText\n';
        },
      );
      return '\n$itemsFormatted\n';
    },
  );

  processed = processed.replaceAll(RegExp(r'<(ul|ol)[^>]*>', caseSensitive: false), '\n');
  processed = processed.replaceAll(RegExp(r'</(ul|ol)>', caseSensitive: false), '\n');
  processed = processed.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '  • ');
  processed = processed.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

  processed = processed.replaceAll(RegExp(r'<[^>]*>'), '');

  processed = processed
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");

  return processed.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

String resolveMediaUrl(String url) {
  if (url.startsWith('/')) {
    return '${AppConfig.serverHost}$url';
  }
  return url;
}

class PortalSettings {
  final String siteName;
  final String tagline;
  final String logoUrl;
  final bool maintenanceMode;
  final bool allowPublicRegistration;
  final List<HeroSlide> heroSlides;
  final AboutSectionData about;
  final AboutBannerData aboutBanner;
  final List<OrganizationMember> organization;
  final List<FeatureItem> features;
  final List<FaqItem> faqs;
  final ContactInfo contacts;
  final TermsConditionsData termsConditions;

  const PortalSettings({
    this.siteName = 'IKA JTK POLBAN',
    this.tagline = 'Portal Alumni Teknik Komputer dan Informatika POLBAN',
    this.logoUrl = '',
    this.maintenanceMode = false,
    this.allowPublicRegistration = true,
    this.heroSlides = const [],
    this.about = const AboutSectionData(),
    this.aboutBanner = const AboutBannerData(),
    this.organization = const [],
    this.features = const [],
    this.faqs = const [],
    this.contacts = const ContactInfo(),
    this.termsConditions = const TermsConditionsData(),
  });

  factory PortalSettings.fromJson(Map<String, dynamic> json) {
    List<HeroSlide> parseHeroSlides(dynamic value) {
      if (value is List) {
        return value.map((e) => HeroSlide.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      return [];
    }

    AboutSectionData parseAbout(dynamic value) {
      if (value is Map) {
        return AboutSectionData.fromJson(Map<String, dynamic>.from(value));
      }
      return const AboutSectionData();
    }

    AboutBannerData parseBanner(dynamic value) {
      if (value is Map) {
        return AboutBannerData.fromJson(Map<String, dynamic>.from(value));
      }
      return const AboutBannerData();
    }

    List<OrganizationMember> parseOrganization(dynamic value) {
      if (value is List) {
        return value.map((e) => OrganizationMember.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      return [];
    }

    List<FeatureItem> parseFeatures(dynamic value) {
      if (value is List) {
        return value.map((e) => FeatureItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      return [];
    }

    List<FaqItem> parseFaqs(dynamic value) {
      if (value is List) {
        return value.map((e) => FaqItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      return [];
    }

    ContactInfo parseContacts(dynamic value) {
      if (value is Map) {
        return ContactInfo.fromJson(Map<String, dynamic>.from(value));
      }
      return const ContactInfo();
    }

    TermsConditionsData parseTermsConditions(dynamic value) {
      if (value is Map) {
        return TermsConditionsData.fromJson(Map<String, dynamic>.from(value));
      }
      return const TermsConditionsData();
    }

    return PortalSettings(
      siteName: json['site_name']?.toString() ?? 'IKA JTK POLBAN',
      tagline: json['tagline']?.toString() ?? '',
      logoUrl: resolveMediaUrl(json['logo_url']?.toString() ?? ''),
      maintenanceMode: json['maintenance_mode'] == true || json['maintenance_mode'] == 1 || json['maintenance_mode']?.toString().toLowerCase() == 'true' || json['maintenance_mode']?.toString() == '1',
      allowPublicRegistration: json['allow_public_registration'] == true || json['allow_public_registration'] == 1 || json['allow_public_registration']?.toString().toLowerCase() == 'true' || json['allow_public_registration']?.toString() == '1',
      heroSlides: parseHeroSlides(json['hero_slides']),
      about: parseAbout(json['about']),
      aboutBanner: parseBanner(json['about_banner']),
      organization: parseOrganization(json['organization']),
      features: parseFeatures(json['features']),
      faqs: parseFaqs(json['faqs']),
      contacts: parseContacts(json['contacts']),
      termsConditions: parseTermsConditions(json['terms_conditions']),
    );
  }
}

class HeroSlide {
  final String imageUrl;
  final String overlayTitle;
  final String badgeLabel;
  final String newsTitle;
  final String newsExcerpt;
  final double bgImageX;
  final double bgImageY;
  final bool showOverlay;
  final String overlayColor;
  final double overlayOpacity;

  const HeroSlide({
    this.imageUrl = '',
    this.overlayTitle = '',
    this.badgeLabel = '',
    this.newsTitle = '',
    this.newsExcerpt = '',
    this.bgImageX = 50,
    this.bgImageY = 50,
    this.showOverlay = true,
    this.overlayColor = '#1E2A4D',
    this.overlayOpacity = 40,
  });

  factory HeroSlide.fromJson(Map<String, dynamic> json) {
    return HeroSlide(
      imageUrl: resolveMediaUrl(json['imageUrl']?.toString() ?? ''),
      overlayTitle: json['overlayTitle']?.toString() ?? json['judul']?.toString() ?? '',
      badgeLabel: json['badgeLabel']?.toString() ?? json['badge']?.toString() ?? '',
      newsTitle: json['newsTitle']?.toString() ?? json['title']?.toString() ?? '',
      newsExcerpt: stripHtml(json['newsExcerpt']?.toString() ?? json['excerpt']?.toString() ?? ''),
      bgImageX: (json['bgImageX'] as num?)?.toDouble() ?? 50,
      bgImageY: (json['bgImageY'] as num?)?.toDouble() ?? 50,
      showOverlay: json['showOverlay'] ?? true,
      overlayColor: json['overlayColor']?.toString() ?? '#1E2A4D',
      overlayOpacity: (json['overlayOpacity'] as num?)?.toDouble() ?? 40,
    );
  }
}

class AboutSectionData {
  final String title;
  final String content;
  final String label;
  final String bgColor;

  const AboutSectionData({
    this.title = 'Apa itu IKA JTK?',
    this.content = '',
    this.label = 'Definisi IKA JTK',
    this.bgColor = '#FFF1E5',
  });

  factory AboutSectionData.fromJson(Map<String, dynamic> json) {
    return AboutSectionData(
      title: json['title']?.toString() ?? 'Apa itu IKA JTK?',
      content: json['content']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Definisi IKA JTK',
      bgColor: json['bgColor']?.toString() ?? '#FFF1E5',
    );
  }
}

class AboutBannerData {
  final String imageUrl;
  final String tagline;
  final String headerLine1;
  final String headerLine2;
  final String logoUrl;
  final double logoWidth;
  final double logoHeight;
  final double logoX;
  final double logoY;
  final double bgImageX;
  final double bgImageY;
  final double taglineX;
  final double taglineY;
  final bool showOverlay;
  final String overlayColor;
  final double overlayOpacity;

  const AboutBannerData({
    this.imageUrl = '',
    this.tagline = 'Bersama, Berdampak.',
    this.headerLine1 = 'JURUSAN TEKNIK KOMPUTER DAN INFORMATIKA',
    this.headerLine2 = 'POLITEKNIK NEGERI BANDUNG',
    this.logoUrl = '',
    this.logoWidth = 48,
    this.logoHeight = 48,
    this.logoX = 80,
    this.logoY = 5,
    this.bgImageX = 50,
    this.bgImageY = 50,
    this.taglineX = 5,
    this.taglineY = 75,
    this.showOverlay = true,
    this.overlayColor = '#1a2744',
    this.overlayOpacity = 80,
  });

  factory AboutBannerData.fromJson(Map<String, dynamic> json) {
    const fallbackX = {'top-right': 80.0, 'top-left': 5.0, 'bottom-right': 80.0, 'bottom-left': 5.0};
    const fallbackY = {'top-right': 5.0, 'top-left': 5.0, 'bottom-right': 75.0, 'bottom-left': 75.0};
    final oldPos = json['logoPosition']?.toString();
    final fx = (json['logoX'] as num?)?.toDouble();
    final fy = (json['logoY'] as num?)?.toDouble();
    return AboutBannerData(
      imageUrl: resolveMediaUrl(json['imageUrl']?.toString() ?? ''),
      tagline: json['tagline']?.toString() ?? 'Bersama, Berdampak.',
      headerLine1: json['headerLine1']?.toString() ?? 'JURUSAN TEKNIK KOMPUTER DAN INFORMATIKA',
      headerLine2: json['headerLine2']?.toString() ?? 'POLITEKNIK NEGERI BANDUNG',
      logoUrl: resolveMediaUrl(json['logoUrl']?.toString() ?? ''),
      logoWidth: (json['logoWidth'] as num?)?.toDouble() ?? 48,
      logoHeight: (json['logoHeight'] as num?)?.toDouble() ?? 48,
      logoX: fx ?? (oldPos != null ? (fallbackX[oldPos] ?? 80.0) : 80.0),
      logoY: fy ?? (oldPos != null ? (fallbackY[oldPos] ?? 5.0) : 5.0),
      bgImageX: (json['bgImageX'] as num?)?.toDouble() ?? 50,
      bgImageY: (json['bgImageY'] as num?)?.toDouble() ?? 50,
      taglineX: (json['taglineX'] as num?)?.toDouble() ?? 5,
      taglineY: (json['taglineY'] as num?)?.toDouble() ?? 75,
      showOverlay: json['showOverlay'] == true,
      overlayColor: json['overlayColor']?.toString() ?? '#1a2744',
      overlayOpacity: (json['overlayOpacity'] as num?)?.toDouble() ?? 80,
    );
  }
}

class OrganizationMember {
  final String nama;
  final String jabatan;
  final String batch;
  final String imageUrl;

  const OrganizationMember({
    this.nama = '',
    this.jabatan = '',
    this.batch = '',
    this.imageUrl = '',
  });

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    return OrganizationMember(
      nama: json['nama']?.toString() ?? '',
      jabatan: json['jabatan']?.toString() ?? '',
      batch: json['batch']?.toString() ?? '',
      imageUrl: resolveMediaUrl(json['imageUrl']?.toString() ?? ''),
    );
  }
}

class FeatureItem {
  final String judul;
  final String deskripsi;
  final String iconKey;

  const FeatureItem({
    this.judul = '',
    this.deskripsi = '',
    this.iconKey = 'star',
  });

  factory FeatureItem.fromJson(Map<String, dynamic> json) {
    return FeatureItem(
      judul: stripHtml(json['judul']?.toString() ?? json['title']?.toString() ?? ''),
      deskripsi: stripHtml(json['deskripsi']?.toString() ?? json['desc']?.toString() ?? ''),
      iconKey: json['iconKey']?.toString() ?? json['icon']?.toString() ?? 'star',
    );
  }
}

class FaqItem {
  final String pertanyaan;
  final String jawaban;

  const FaqItem({this.pertanyaan = '', this.jawaban = ''});

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      pertanyaan: json['pertanyaan']?.toString() ?? '',
      jawaban: json['jawaban']?.toString() ?? '',
    );
  }
}

class ContactInfo {
  final String instagram;
  final String email;
  final String whatsapp;
  final String alamat;

  const ContactInfo({
    this.instagram = '@ikajtk.id',
    this.email = 'pengurus@ikajtk.id',
    this.whatsapp = '',
    this.alamat = 'Politeknik Negeri Bandung',
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      instagram: json['instagram']?.toString() ?? '@ikajtk.id',
      email: json['email']?.toString() ?? 'pengurus@ikajtk.id',
      whatsapp: json['whatsapp']?.toString() ?? '',
      alamat: stripHtml(json['alamat']?.toString() ?? 'Politeknik Negeri Bandung'),
    );
  }
}

class TermsConditionsData {
  final String title;
  final String subtitle;
  final String lastUpdated;
  final String intro;
  final String content;

  const TermsConditionsData({
    this.title = 'Syarat & Ketentuan Pengguna (Terms & Conditions)',
    this.subtitle = 'Perjanjian hukum, ketentuan keanggotaan, dan aturan penggunaan layanan Portal IKA JTK POLBAN.',
    this.lastUpdated = '16 Juli 2026',
    this.intro = 'Selamat datang di Portal Resmi Ikatan Alumni Teknik Komputer Politeknik Negeri Bandung (IKA JTK POLBAN). Dokumen Syarat dan Ketentuan Pengguna ("Perjanjian") ini mengatur hak, kewajiban, dan batasan hukum antara Anda sebagai pengguna dengan organisasi IKA JTK POLBAN. Dengan mendaftar, mengakses, atau menggunakan layanan pada portal ini, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh isi ketentuan di bawah ini.',
    this.content = '<h3>1. Kualifikasi dan Verifikasi Keanggotaan</h3><p>Portal ini disediakan khusus untuk melayani jejaring komunikasi dan profesional civitas akademika serta alumni Jurusan Teknik Komputer POLBAN:</p><ul><li>Pendaftaran akun wajib menggunakan identitas asli yang akurat, termasuk Nama Lengkap, Tahun Angkatan, dan Nomor Alumni / bukti kelulusan yang sah.</li><li>Setiap pendaftaran akun baru akan melalui proses verifikasi dan validasi oleh tim Admin / Pengurus IKA JTK POLBAN sebelum status akun diaktifkan secara penuh.</li><li>Tindakan memalsukan identitas akademik, memanipulasi data kelulusan, atau mengatasnamakan alumni lain merupakan pelanggaran hukum berat yang berakibat pada pembatalan akun permanen, pelaporan kepada almamater, serta tindakan hukum sesuai undang-undang yang berlaku.</li></ul><h3>2. Keamanan Akun dan Tanggung Jawab Pengguna</h3><ul><li><strong>Kerahasiaan Kredensial:</strong> Anda bertanggung jawab penuh untuk menjaga kerahasiaan username, kata sandi, serta token akses akun Anda.</li><li><strong>Aktivitas Akun:</strong> Segala bentuk aktivitas, transaksi, dan publikasi konten yang dilakukan melalui akun Anda sepenuhnya menjadi tanggung jawab Anda pribadi.</li><li><strong>Larangan Berbagi Akun:</strong> Akun alumni bersifat personal dan tidak dapat dialihkan, dipinjamkan, atau diperjualbelikan kepada pihak lain dalam kondisi apa pun.</li><li><strong>Pelaporan Insiden:</strong> Jika Anda mengetahui atau mencurigai adanya akses ilegal atau kebocoran kredensial pada akun Anda, Anda wajib segera melaporkannya kepada Pengurus IKA JTK.</li></ul><h3>3. Aturan Penggunaan Layanan (Acceptable Use Policy)</h3><p>Dalam berinteraksi dan memanfaatkan fitur Portal IKA JTK (seperti Direktori Alumni, Lowongan Kerja, Berita, dan Pemilu), setiap pengguna dilarang keras untuk:</p><ul><li>Mengunggah atau menyebarkan informasi palsu (hoaks), penipuan lowongan kerja fiktif, ujaran kebencian, pelecehan, rasisme, pornografi, atau konten yang menyinggung SARA.</li><li>Melakukan aktivitas yang merusak marwah, martabat, dan nama baik organisasi IKA JTK maupun almamater Politeknik Negeri Bandung.</li><li>Melakukan pengumpulan data massal (data scraping/crawling) terhadap direktori alumni atau kontak pribadi anggota tanpa izin tertulis dari Pengurus Pusat IKA JTK POLBAN.</li><li>Melakukan serangan siber, penyebaran virus/malware, atau manipulasi sistem pemungutan suara elektronik (E-Voting/Pemilu Alumni).</li></ul><h3>4. Hak Kekayaan Intelektual dan Lisensi Konten</h3><p>Seluruh hak cipta atas arsitektur sistem, desain grafis, logo organisasi, dan basis data Portal IKA JTK adalah milik sah IKA JTK POLBAN. Terkait konten yang Anda kirimkan (berita, testimoni, lowongan kerja):</p><ul><li><strong>Kepemilikan Konten:</strong> Anda tetap menjadi pemilik hak cipta atas materi/konten yang Anda tulis atau publikasikan di portal ini.</li><li><strong>Lisensi Penayangan:</strong> Dengan mengunggah konten ke dalam portal, Anda memberikan hak non-eksklusif, bebas royalti, dan dapat dialihkan kepada IKA JTK POLBAN untuk menayangkan, mendistribusikan, dan mempromosikan konten tersebut demi kemajuan komunitas alumni.</li><li><strong>Tanggung Jawab Hukum:</strong> Anda menjamin bahwa konten yang Anda unggah tidak melanggar hak cipta pihak ketiga mana pun dan membebaskan IKA JTK dari segala tuntutan hukum yang timbul dari konten Anda.</li></ul><h3>5. Batasan Tanggung Jawab (Limitation of Liability)</h3><p>Layanan portal ini disediakan sebagaimana adanya ("as is" dan "as available"). IKA JTK POLBAN berupaya maksimal menjaga keandalan dan keamanan portal, namun tidak memberikan jaminan bahwa layanan akan selalu bebas dari gangguan teknis, keterlambatan, atau pemeliharaan sistem. IKA JTK POLBAN juga tidak bertanggung jawab atas kerugian material maupun immaterial yang timbul akibat interaksi, kesepakatan karir/bisnis, atau transaksi langsung antar alumni yang dilakukan di luar platform portal.</p><h3>6. Sanksi, Pembatasan, dan Penghentian Layanan</h3><p>Pengurus dan Admin IKA JTK POLBAN memiliki hak prerogatif untuk memberikan peringatan tertulis, membatasi hak akses fitur (suspend), atau menonaktifkan akun secara permanen apabila pengguna terbukti melanggar Syarat dan Ketentuan Pengguna ini, melanggar Kode Etik Komunitas, atau merugikan kepentingan organisasi.</p><h3>7. Perubahan Ketentuan dan Hukum yang Berlaku</h3><p>IKA JTK POLBAN berhak untuk memperbarui atau mengubah Syarat dan Ketentuan Pengguna ini sewaktu-waktu agar selaras dengan perkembangan organisasi dan regulasi yang berlaku. Perubahan akan diinformasikan melalui portal. Perjanjian ini tunduk dan ditafsirkan berdasarkan Hukum Republik Indonesia. Segala sengketa yang timbul akan diselesaikan terlebih dahulu secara musyawarah dan kekeluargaan di bawah mediasi Pengurus Pusat IKA JTK POLBAN.</p>',
  });

  factory TermsConditionsData.fromJson(Map<String, dynamic> json) {
    return TermsConditionsData(
      title: json['title']?.toString() ?? 'Syarat & Ketentuan Pengguna (Terms & Conditions)',
      subtitle: json['subtitle']?.toString() ?? 'Perjanjian hukum, ketentuan keanggotaan, dan aturan penggunaan layanan Portal IKA JTK POLBAN.',
      lastUpdated: json['last_updated']?.toString() ?? '16 Juli 2026',
      intro: json['intro']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }
}

final portalConfigProvider = FutureProvider<PortalSettings>((ref) async {
  final baseUrl = AppConfig.apiBaseUrl;
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final res = await http.get(
      Uri.parse('$baseUrl/portal/config?_t=$timestamp'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return PortalSettings.fromJson(data);
    } else {
      print('portalConfigProvider HTTP error: ${res.statusCode}');
    }
  } catch (e) {
    print('portalConfigProvider exception: $e');
  }
  return const PortalSettings();
});

/// Watch [portalConfigAutoRefreshProvider] anywhere in the widget tree to
/// enable automatic 5-second polling of portal config. Kept alive for the
/// entire app lifetime so the timer runs continuously.
final portalConfigAutoRefreshProvider = Provider((ref) {
  final timer = Timer.periodic(const Duration(seconds: 5), (_) {
    ref.invalidate(portalConfigProvider);
  });
  ref.onDispose(() => timer.cancel());
  return timer;
});
