import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';

class _Faq {
  final String pertanyaan;
  final String jawaban;
  const _Faq(this.pertanyaan, this.jawaban);
}

const _faqs = <_Faq>[
  _Faq(
    'Bagaimana cara mendaftar akun?',
    'Silakan klik Menu lalu pilih menu Register. Isi formulir yang diberikan lalu klik Daftar. Setelah itu Admin IKA JTK akan memverifikasi data Anda dan melakukan proses approval untuk kemudian user bisa login ke halaman Portal IKA JTK.',
  ),
  _Faq(
    'Apa itu Sistem Informasi Alumni?',
    'Sistem Informasi Alumni IKA JTK POLBAN adalah platform digital terintegrasi yang dirancang untuk mempererat koneksi antaralumni, memfasilitasi pertukaran informasi peluang karir, dan mendukung pengembangan almamater Teknik Komputer POLBAN.',
  ),
  _Faq(
    'Bagaimana cara melihat alumni IKA JTK?',
    'Anda bisa register terlebih dahulu, kemudian login ke Portal IKA JTK dan pilih menu List Member IKA JTK.',
  ),
  _Faq(
    'Bagaimana cara saya mengedit data yang salah?',
    'Silakan Anda login menggunakan akun aktif Anda di Portal IKA JTK lalu klik Update My Profile.',
  ),
  _Faq(
    'Bagaimana jika lupa kata sandi?',
    'Anda dapat menggunakan fitur Lupa Kata Sandi pada halaman Login. Masukkan alamat email yang terdaftar untuk menerima tautan atur ulang kata sandi.',
  ),
  _Faq(
    'Saya tidak ingin data saya ada disini!',
    'Silakan hubungi Admin IKA JTK di pengurus@ikajtk.id untuk menghapus akun Anda dari sistem database kami.',
  ),
];

class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const PublicAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 64,
            maxContentWidth: 960,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DAFTAR / TERIMA KASIH',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Terima kasih sudah mendaftar',
                  style: TextStyle(
                    color: AppColors.gray900,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text:
                            'Silakan cek email Anda secara berkala atau hubungi ',
                        style: TextStyle(
                          color: AppColors.gray600,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      TextSpan(
                        text: 'pengurus@ikajtk.id',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(
                        text: ' untuk bantuan',
                        style: TextStyle(
                          color: AppColors.gray600,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 40, height: 3, color: AppColors.accent),
                const SizedBox(height: 40),

                // FAQ List
                ..._faqs.map((f) => _FaqItem(faq: f)),

                const SizedBox(height: 24),
                InkWell(
                  onTap: () => context.go('/'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kembali ke Beranda',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.home_outlined,
                          size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final _Faq faq;
  const _FaqItem({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big red ? icon
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '?',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq.pertanyaan,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  faq.jawaban,
                  style: const TextStyle(
                    color: AppColors.gray600,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
