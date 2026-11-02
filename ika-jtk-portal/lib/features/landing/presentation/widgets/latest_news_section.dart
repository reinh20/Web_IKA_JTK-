import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_data.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/portal_network_image.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/section_wrapper.dart';
import '../../../berita/providers/berita_provider.dart';

class LatestNewsSection extends ConsumerWidget {
  const LatestNewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beritaState = ref.watch(beritaProvider);
    final allBerita = beritaState.items;
    final featuredList = allBerita.take(2).toList();
    final compactList = allBerita.skip(2).take(4).toList();

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.tablet;

    return SectionWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            label: 'Berita & Update',
            title: 'Kabar Terkini Alumni',
            description:
                'Simak kabar terbaru, cerita inspiratif, dan informasi penting seputar alumni Teknik Komputer POLBAN.',
          ),
          const SizedBox(height: 32),
          if (beritaState.isLoading && allBerita.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (allBerita.isEmpty)
            const EmptyState(
              icon: Icons.article_outlined,
              title: 'Belum ada berita',
              message:
                  'Saat ini belum ada berita yang dipublikasikan. Silakan cek kembali nanti.',
            )
          else if (isMobile)
            Column(
              children: featuredList
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FeaturedNewsCard(item: b),
                      ))
                  .toList(),
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: featuredList
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: e.key == featuredList.length - 1 ? 0 : 24),
                          child: _FeaturedNewsCard(item: e.value),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (compactList.isNotEmpty) ...[
            const SizedBox(height: 48),
            const Text(
              'Berita Lainnya',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Container(width: 32, height: 2, color: AppColors.accent),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: compactList.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 1 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 24,
                mainAxisExtent: 110,
              ),
              itemBuilder: (_, i) => _CompactNewsCard(item: compactList[i]),
            ),
          ],
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => context.go('/berita'),
            child: const Text('Lihat Semua Berita'),
          ),
        ],
      ),
    );
  }
}

class _FeaturedNewsCard extends StatelessWidget {
  final BeritaContent item;
  const _FeaturedNewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => context.go('/berita/${item.id}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: PortalNetworkImage(
                    url: item.imageUrl,
                    placeholderIcon: Icons.article_outlined,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: AppColors.gray500),
                        const SizedBox(width: 6),
                        Text(
                          'Disposisi pada ${item.tanggal}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.excerpt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray600,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactNewsCard extends StatelessWidget {
  final BeritaContent item;
  const _CompactNewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => context.go('/berita/${item.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: PortalNetworkImage(
                    url: item.imageUrl,
                    placeholderIcon: Icons.article_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 10, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(
                          'Disposisi pada ${item.tanggal}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.gray600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
