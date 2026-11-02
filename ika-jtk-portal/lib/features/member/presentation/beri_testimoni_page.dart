import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/testimoni_provider.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import 'widgets/member_app_bar.dart';

class BeriTestimoniPage extends ConsumerStatefulWidget {
  const BeriTestimoniPage({super.key});

  @override
  ConsumerState<BeriTestimoniPage> createState() => _BeriTestimoniPageState();
}

class _BeriTestimoniPageState extends ConsumerState<BeriTestimoniPage> {
  final _nama = TextEditingController();
  final _isi = TextEditingController();
  final _angkatanCtrl = TextEditingController();
  String _visibility = 'public';
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nama.text = user?.nama ?? '';
    _angkatanCtrl.text = user?.angkatan?.toString() ?? '';
    Future.microtask(() {
      final token = ref.read(authProvider).token;
      ref.read(testimoniProvider.notifier).fetchPublic(token: token);
      if (token != null && token.isNotEmpty) {
        ref.read(testimoniProvider.notifier).fetchMyTestimoni(token: token).then((_) {
          _checkAndShowRejectionPopup();
        });
      }
    });
  }

  Future<void> _checkAndShowRejectionPopup() async {
    if (!mounted) return;
    final myLatest = ref.read(testimoniProvider).myLatest;
    if (myLatest == null) return;

    final status = myLatest.status.toLowerCase();
    if (status != 'rejected') return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'testimoni_rejected_shown_${myLatest.id}_${myLatest.rejectCount}';
    final alreadyShown = prefs.getBool(key) ?? false;

    if (alreadyShown || !mounted) return;

    await prefs.setBool(key, true);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: AppColors.danger, size: 18),
            ),
            const SizedBox(width: 12),
            Text((myLatest.rejectCount ?? 0) >= 3 ? 'Ajukan Ulang Testimoni' : 'Testimoni Ditolak'),
          ],
        ),
        content: Text(
          (myLatest.rejectCount ?? 0) >= 3
              ? 'Silakan ajukan ulang testimoni Anda.'
              : (myLatest.rejectReason != null && myLatest.rejectReason!.isNotEmpty)
                  ? 'Pengajuan testimoni Anda sebelumnya ditolak dengan alasan:\n\n"${myLatest.rejectReason}"\n\nSilakan ajukan testimoni baru yang telah diperbaiki. (Maksimal 3 kali penolakan. Jika pengajuan selanjutnya kembali ditolak, testimoni akan dihapus oleh admin).'
                  : 'Pengajuan testimoni Anda sebelumnya telah ditolak oleh admin. Anda dapat mengajukan testimoni baru sebagai pengganti. (Maksimal 3 kali penolakan. Jika pengajuan selanjutnya kembali ditolak, testimoni akan dihapus oleh admin).',
          style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Sembunyikan badge SETELAH alumni klik "Mengerti"
              ref.read(testimoniProvider.notifier).markRejectionAsRead();
            },
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nama.dispose();
    _isi.dispose();
    _angkatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isi.text.trim().isEmpty) return;
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi berakhir, silakan masuk kembali.')),
        );
      }
      return;
    }

    final error = await ref.read(testimoniProvider.notifier).submitTestimoni(
          isi: _isi.text.trim(),
          visibility: _visibility,
          token: token,
        );

    if (!mounted) return;
    if (error == null) {
      setState(() => _submitted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final testimoniState = ref.watch(testimoniProvider);
    final myLatest = testimoniState.myLatest;
    final myStatus = myLatest?.status.toLowerCase() ?? '';

    Widget mainContent;
    
    final user = ref.watch(authProvider).user;
    if (user != null) {
      if (_nama.text.isEmpty) _nama.text = user.nama;
      if (_angkatanCtrl.text.isEmpty) _angkatanCtrl.text = user.angkatan?.toString() ?? '';
    }
    final isApproved = user != null && 
        ['APPROVED', 'ACTIVE', 'VERIFIED'].contains(user.status?.name.toUpperCase());

    if (!isApproved) {
      mainContent = _unapprovedView();
    } else if (_submitted) {
      mainContent = _successView();
    } else if (testimoniState.myLatestLoading) {
      mainContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (myStatus == 'pending') {
      mainContent = _pendingView();
    } else if (myStatus == 'published') {
      mainContent = _approvedView(myLatest!);
    } else {
      // rejected or no testimoni — can submit (new or re-submit)
      mainContent = Column(
        children: [
          _buildForm(testimoniState.myLatest),
        ],
      );
    }

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const MemberAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: (_submitted || myStatus == 'pending' || myStatus == 'published') ? 120 : 40,
            maxContentWidth: 720,
            child: mainContent,
          ),
          const SizedBox(height: 40),
          const SiteFooter(),
        ],
      ),
    );
  }

  Widget _unapprovedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AKSES DITOLAK',
          style: TextStyle(
            color: AppColors.danger,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Belum Disetujui',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Hanya alumni yang akunnya sudah disetujui (Approved) oleh admin yang dapat mengirimkan testimoni.',
          style: TextStyle(color: AppColors.gray700, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 24),
        Container(width: 48, height: 2, color: AppColors.accent),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => GoRouter.of(context).go('/member'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.home_outlined, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pendingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DALAM PROSES REVIEW',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Terima Kasih!',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Testimoni kamu telah berhasil dikirim dan sedang dalam proses kurasi oleh tim admin.',
          style: TextStyle(color: AppColors.gray700, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 12),
        const Text(
          'Kami percaya bahwa cerita dan pengalaman para alumni dapat menjadi inspirasi bagi generasi berikutnya, serta memperkuat koneksi antar alumni.',
          style: TextStyle(color: AppColors.gray700, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 24),
        Container(width: 48, height: 2, color: AppColors.accent),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => GoRouter.of(context).go('/member'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.home_outlined, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _approvedView(MyTestimoniInfo item) {
    final user = ref.watch(authProvider).user;
    final mockTestimoni = Testimoni(
      id: item.id,
      alumniNama: user?.nama ?? '',
      alumniAngkatan: user?.angkatan?.toString() ?? '',
      alumniAvatarUrl: user?.avatarUrl ?? '',
      isi: item.isi,
      status: item.status,
      createdAt: item.createdAt,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUDAH DISETUJUI',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Testimoni Anda Sudah Aktif!',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Testimoni Anda telah disetujui dan sudah ditampilkan. Terima kasih telah berbagi cerita dan pengalaman Anda.',
          style: TextStyle(color: AppColors.gray700, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 24),
        Container(width: 48, height: 2, color: AppColors.accent),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => GoRouter.of(context).go('/member'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.home_outlined, color: AppColors.primary, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 48),
        const Text(
          'Testimoni Anda',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 16),
        _TestimoniCard(item: mockTestimoni),
      ],
    );
  }

  Widget _buildForm(MyTestimoniInfo? myLatest) {
    final isRejected = myLatest?.status.toLowerCase() == 'rejected';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRejected)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (myLatest?.rejectCount ?? 0) >= 3
                              ? 'Ajukan Ulang Testimoni'
                              : 'Testimoni Sebelumnya Ditolak',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (myLatest?.rejectCount ?? 0) >= 3
                              ? 'Silakan ajukan ulang testimoni Anda.'
                              : (myLatest?.rejectReason != null && myLatest!.rejectReason!.isNotEmpty)
                                  ? 'Alasan admin: "${myLatest.rejectReason}"\n\nSilakan perbaiki testimoni Anda dan ajukan kembali. (Maksimal 3 kali penolakan. Jika pengajuan selanjutnya kembali ditolak, testimoni akan dihapus oleh admin)'
                                  : 'Testimoni Anda ditolak oleh admin. Silakan buat testimoni baru yang lebih sesuai. (Maksimal 3 kali penolakan. Jika pengajuan selanjutnya kembali ditolak, testimoni akan dihapus oleh admin)',
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SectionLabel(
            label: 'Beri Testimoni',
            title: 'Bagikan Ceritamu Sebagai Alumni',
            description:
                'Ceritakan pengalaman, dampak, atau bagaimana jejaring IKA JTK membantu karier dan kehidupan Anda.',
          ),
          const SizedBox(height: 24),
          const _Label('Nama Lengkap'),
          TextField(
            controller: _nama,
            readOnly: true,
            enabled: false,
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 16),
          const _Label('Angkatan'),
          TextField(
            controller: _angkatanCtrl,
            readOnly: true,
            enabled: false,
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 16),
          const _Label('Isi Testimoni'),
          TextField(
            controller: _isi,
            maxLines: 6,
            decoration: const InputDecoration(
                hintText: 'Ceritakan pengalaman Anda...'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Apakah Anda bersedia testimoni ini ditampilkan di publik?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _RadioOpt(
                label: 'Ya, tampilkan di publik',
                selected: _visibility == 'public',
                onTap: () => setState(() => _visibility = 'public'),
              ),
              _RadioOpt(
                label: 'Tidak, hanya untuk internal IKA',
                selected: _visibility == 'private',
                onTap: () => setState(() => _visibility = 'private'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Builder(
                builder: (context) {
                  final isSubmitting =
                      ref.watch(testimoniProvider).isSubmitting;
                  return ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 16),
                    label: Text(
                        isSubmitting ? 'Mengirim...' : 'Kirim Testimoni'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BERHASIL',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Terima Kasih!',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Testimoni kamu telah berhasil dikirim dan sedang dalam proses kurasi oleh tim admin.',
          style: TextStyle(color: AppColors.gray700, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 12),
        const Text(
          'Kami percaya bahwa cerita dan pengalaman para alumni dapat menjadi inspirasi bagi generasi berikutnya, serta memperkuat koneksi antar alumni.',
          style: TextStyle(color: AppColors.gray700, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 24),
        Container(width: 48, height: 2, color: AppColors.accent),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => GoRouter.of(context).go('/member'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.home_outlined, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ],
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

class _TestimoniCard extends StatelessWidget {
  final Testimoni item;
  const _TestimoniCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${item.isi}"',
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.gray800,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.gray100,
                backgroundImage: item.alumniAvatarUrl.isNotEmpty
                    ? NetworkImage(item.alumniAvatarUrl)
                    : null,
                child: item.alumniAvatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 18, color: AppColors.gray600)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.alumniNama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  if (item.alumniAngkatan.isNotEmpty)
                    Text(
                      'Angkatan ${item.alumniAngkatan}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadioOpt extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioOpt({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.gray300,
                  width: 2,
                ),
              ),
              child: Center(
                child: selected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 14, color: AppColors.gray800)),
          ],
        ),
      ),
    );
  }
}
