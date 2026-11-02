import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';

class SuggestionPage extends ConsumerStatefulWidget {
  const SuggestionPage({super.key});

  @override
  ConsumerState<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends ConsumerState<SuggestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  String _kategori = 'Kritik';
  final _email = TextEditingController();
  final _subjek = TextEditingController();
  final _pesan = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _subjek.dispose();
    _pesan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: '')
              : const PublicAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 56,
            maxContentWidth: 720,
            child: _submitted ? _SuccessView() : _buildForm(),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KRITIK & SARAN',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Form Kritik & Saran',
              style: TextStyle(
                color: AppColors.gray900,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Container(width: 40, height: 3, color: AppColors.accent),
            const SizedBox(height: 8),
            const Text(
              'Sampaikan saran atau kritik kamu untuk kemajuan IKA JTK Polban. Kami menghargai setiap masukan untuk perbaikan platform dan organisasi.',
              style: TextStyle(color: AppColors.gray600, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            const _Label('Nama Lengkap'),
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(hintText: 'Nama lengkap kamu'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            const _Label('Kategori'),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              items: const [
                DropdownMenuItem(value: 'Kritik', child: Text('Kritik')),
                DropdownMenuItem(value: 'Saran', child: Text('Saran')),
                DropdownMenuItem(value: 'Pertanyaan', child: Text('Pertanyaan')),
              ],
              onChanged: (v) => setState(() => _kategori = v ?? 'Kritik'),
            ),
            const SizedBox(height: 16),
            const _Label('Email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'nama@email.com'),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Wajib diisi';
                if (!s.contains('@')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _Label('Pesan'),
            TextFormField(
              controller: _pesan,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Tulis pesan kamu di sini...',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _submitted = true);
                    }
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Kirim Masukan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.success, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'BERHASIL',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Terima Kasih atas Masukanmu!',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 40, height: 3, color: AppColors.accent),
          const SizedBox(height: 16),
          const Text(
            'Masukan kamu sudah kami terima dan akan kami baca dengan seksama. Tim IKA JTK akan menggunakan masukan ini untuk terus memperbaiki platform dan organisasi alumni kita.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray600, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => GoRouter.of(context).go('/'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Kembali ke Beranda'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.gray800,
        ),
      ),
    );
  }
}
