import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/breadcrumb.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../../shared/widgets/warning_banner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../providers/pemilu_provider.dart';
import 'widgets/candidate_radio_tile.dart';

class VotePage extends ConsumerStatefulWidget {
  const VotePage({super.key});

  @override
  ConsumerState<VotePage> createState() => _VotePageState();
}

class _VotePageState extends ConsumerState<VotePage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final pemiluState = ref.watch(pemiluProvider);
    final auth = ref.watch(authProvider);
    final candidates = pemiluState.candidates;
    final hasVoted = pemiluState.hasVoted;
    final isLoading = pemiluState.isLoading;

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const MemberAppBar(activeKey: 'pemilu'),
          SectionWrapper(
            verticalPadding: 40,
            maxContentWidth: 720,
            child: hasVoted
                ? _successView()
                : _voteForm(auth, candidates, isLoading),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }

  Widget _voteForm(
    AuthState auth,
    List<dynamic> candidates,
    bool isLoading,
  ) {
    final userNama = auth.user?.nama ?? '';
    final userAngkatan = auth.user?.angkatan?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Breadcrumb(items: [
          BreadcrumbItem(label: 'Beranda', onTap: () => context.go('/')),
          BreadcrumbItem(label: 'Pemilu', onTap: () => context.go('/pemilu')),
          const BreadcrumbItem(label: 'Pilih'),
        ]),
        const SizedBox(height: 16),
        const Text(
          'Gunakan Hak Suaramu Hari Ini',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih calon ketua yang menurutmu paling tepat memimpin IKA JTK ke depan. '
          'Satu suara dari kamu berarti besar untuk masa depan kita bersama.',
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 40, height: 3, color: AppColors.accent),
        const SizedBox(height: 24),
        _label('Nama Lengkap'),
        _readonlyInput(userNama.isEmpty ? '—' : userNama),
        const SizedBox(height: 16),
        _label('Angkatan'),
        _readonlyInput(userAngkatan.isEmpty ? '—' : userAngkatan),
        const SizedBox(height: 20),
        _label('Pilih Calon Ketua'),
        const SizedBox(height: 6),
        if (candidates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Belum ada kandidat yang tersedia untuk dipilih.',
              style: TextStyle(color: AppColors.gray500, fontSize: 14),
            ),
          )
        else
          Column(
            children: [
              for (final c in candidates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CandidateRadioTile(
                    candidate: c,
                    selected: _selectedId == c.id,
                    onSelect: (id) => setState(() => _selectedId = id),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        const WarningBanner(
          message:
              'Kamu hanya bisa memilih satu kali. Pastikan pilihanmu sudah sesuai sebelum mengirimkan suara.',
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed:
                (_selectedId != null && !isLoading && candidates.isNotEmpty)
                    ? _submit
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Kirim Suara'),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final id = _selectedId;
    if (id == null) return;
    final token = ref.read(authProvider).token ?? '';
    final error = await ref.read(pemiluProvider.notifier).vote(id, token);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.gray700,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _readonlyInput(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.gray700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _successView() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.how_to_vote,
                color: AppColors.success, size: 36),
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
            'Suaramu Sudah Tercatat!',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 40, height: 3, color: AppColors.accent),
          const SizedBox(height: 16),
          const Text(
            'Terima kasih sudah berpartisipasi dalam PEMILU IKA JTK Polban. '
            'Hasil voting akan diumumkan setelah masa pemilihan berakhir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/pemilu'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Kembali ke PEMILU'),
          ),
        ],
      ),
    );
  }
}
