import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';
import '../../../../shared/widgets/section_wrapper.dart';

class PemiluFaqSection extends StatelessWidget {
  const PemiluFaqSection({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'pertanyaan': 'Siapa yang bisa memilih?',
      'jawaban': 'Semua alumni JTK Polban yang telah mendaftar dan diverifikasi oleh admin.',
    },
    {
      'pertanyaan': 'Saya lupa password akun saya, bagaimana?',
      'jawaban': 'Gunakan fitur “Lupa Password” di halaman login, atau hubungi admin melalui kontak yang tersedia.',
    },
    {
      'pertanyaan': 'Saya sudah memilih, tapi tidak yakin datanya tersimpan.',
      'jawaban': 'Setelah memilih, sistem akan memberikan nomor pemilih unik sebagai bukti. Jika ragu, hubungi admin.',
    },
    {
      'pertanyaan': 'Apakah saya bisa mengganti pilihan?',
      'jawaban': 'Tidak. Pilihan hanya bisa dilakukan satu kali dan tidak dapat diubah demi menjaga integritas pemilu.',
    },
    {
      'pertanyaan': 'Saya ingin tahu lebih dalam tentang calon. Di mana bisa melihat detailnya?',
      'jawaban': 'Klik tombol Lihat Program Kerja Lengkap di masing-masing profil calon.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SectionWrapper(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header FAQ sesuai gambar figma/screenshot
          const Text(
            'F A Q',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Frequently Asked Question',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tanya-Jawab Seputar Pemilu',
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 3,
            color: AppColors.accent, // Garis bawah oranye
          ),
          const SizedBox(height: 48),
          // Daftar Pertanyaan & Jawaban
          Column(
            children: _faqs.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '?',
                        style: TextStyle(
                          color: const Color(0xFFDC2626), // Merah tegas / oranye pekat
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['pertanyaan'] ?? '',
                            style: const TextStyle(
                              color: AppColors.gray900,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['jawaban'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8), // Muted blue-gray
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
