import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/tokens.dart';
import '../../../core/portal_data.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import 'widgets/member_app_bar.dart';
import '../providers/lamaran_provider.dart';

class LamaranPage extends ConsumerStatefulWidget {
  const LamaranPage({super.key});

  @override
  ConsumerState<LamaranPage> createState() => _LamaranPageState();
}

class _LamaranPageState extends ConsumerState<LamaranPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(lamaranProvider.notifier).fetchLamaran(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lamaranProvider);

    return Scaffold(
      body: StickyFooterScrollView(
        controller: _scrollController,
        children: [
          const MemberAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 40,
            maxContentWidth: 920,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/loker'),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Kembali ke Loker'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionLabel(
                  label: 'Lamaran',
                  title: 'Riwayat Lamaran',
                  description:
                      'Pantau status lamaran yang sudah kamu kirim ke perusahaan rekan alumni.',
                ),
                const SizedBox(height: 24),
                if (state.isLoading && state.items.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (state.error != null && state.items.isEmpty)
                  Center(child: Text('Error: ${state.error}'))
                else if (state.items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.gray100),
                    ),
                    child: const Center(
                      child: Text(
                        'Belum ada lamaran. Mulai dari halaman Loker.',
                        style: TextStyle(color: AppColors.gray500),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _LamaranTile(item: state.items[i]),
                  ),
                
                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
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

class _LamaranTile extends StatelessWidget {
  final LamaranEntry item;
  const _LamaranTile({required this.item});

  Color _statusColor() {
    if (item.status == 'Diterima') return AppColors.success;
    if (item.status == 'Ditolak') return AppColors.danger;
    return AppColors.accent;
  }

  Color _statusBg() {
    if (item.status == 'Diterima') return AppColors.successBg;
    if (item.status == 'Ditolak') return const Color(0xFFFEE2E2);
    return AppColors.accentLight;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/loker/${item.lokerId}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CachedNetworkImage(
                  imageUrl: item.logoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(color: AppColors.primaryLight),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.posisi,
                    style: const TextStyle(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    item.perusahaan,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Dilamar pada ${item.dilamarPada}',
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBg(),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  color: _statusColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
