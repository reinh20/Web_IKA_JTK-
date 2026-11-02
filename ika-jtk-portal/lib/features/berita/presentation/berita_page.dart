import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/tokens.dart';
import '../../../core/portal_data.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/portal_network_image.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../providers/berita_provider.dart';

class BeritaListPage extends ConsumerStatefulWidget {
  const BeritaListPage({super.key});

  @override
  ConsumerState<BeritaListPage> createState() => _BeritaListPageState();
}

class _BeritaListPageState extends ConsumerState<BeritaListPage> {
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
      ref.read(beritaProvider.notifier).fetchBerita(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.tablet;

    final beritaState = ref.watch(beritaProvider);
    final heroState = ref.watch(heroBeritaProvider);
    final all = beritaState.items;

    // Fixed categories as requested
    final kategoris = ['Semua', 'Alumni', 'Karir', 'Inspirasi', 'Event', 'Pengabdian', 'Pengumuman', 'Akademik'];

    // Allow hero to show as long as it's page 1 and no search
    final showHero = beritaState.page == 1 && beritaState.search.isEmpty;
    
    final heroBeritas = showHero ? heroState.maybeWhen(
      data: (data) => data,
      orElse: () => <BeritaContent>[],
    ) : <BeritaContent>[];

    
    final others = all;

    return Scaffold(
      body: StickyFooterScrollView(
        controller: _scrollController,
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'berita')
              : const PublicAppBar(activeKey: 'berita'),

          // Hero featured berita
          if (heroBeritas.isNotEmpty)
            SectionWrapper(
              verticalPadding: 56,
              child: CarouselSlider(
                options: CarouselOptions(
                  height: isMobile ? 320 : 480,
                  viewportFraction: 1.0,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 5),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                ),
                items: heroBeritas.map((featured) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          color: AppColors.gray100,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PortalNetworkImage(
                                url: featured.fullImageUrl,
                                placeholderIcon: Icons.article_outlined,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.1),
                                      Colors.black.withValues(alpha: 0.65),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 24,
                                right: 24,
                                bottom: 24,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (featured.kategori.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          featured.kategori.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      featured.judul,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isMobile ? 22 : 32,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () =>
                                          context.go('/berita/${featured.id}'),
                                      child: const Text('Baca Selengkapnya'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),

          // Kategori filter chips
          SectionWrapper(
            verticalPadding: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(
                  label: 'Berita',
                  title: 'Kabar Terkini Alumni',
                  description:
                      'Simak kabar terbaru, cerita inspiratif, dan informasi penting seputar alumni Teknik Komputer POLBAN.',
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kategoris
                      .map((k) => _KategoriChip(
                            label: k,
                            active: k == beritaState.kategori,
                            onTap: () {
                              ref.read(beritaProvider.notifier).fetchBerita(kategori: k);
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // Grid
          SectionWrapper(
            verticalPadding: 24,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 650),
              child: (beritaState.isLoading && others.isEmpty)
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : others.isEmpty
                      ? const EmptyState(
                          icon: Icons.article_outlined,
                          title: 'Belum ada berita',
                          message:
                              'Belum ada berita pada kategori ini. Coba pilih kategori lain.',
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: others.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 1 : 3,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            mainAxisExtent: isMobile ? 420 : 460,
                          ),
                          itemBuilder: (_, i) => _BeritaCard(item: others[i]),
                        ),
            ),
          ),

          if (beritaState.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),

          const SizedBox(height: 80),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _KategoriChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _KategoriChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.gray700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _BeritaCard extends StatelessWidget {
  final BeritaContent item;
  const _BeritaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/berita/${item.id}'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.gray100),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 200,
              child: PortalNetworkImage(
                url: item.imageUrl,
                placeholderIcon: Icons.article_outlined,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.kategori,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gray900,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        item.excerpt,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: AppColors.gray500),
                        const SizedBox(width: 6),
                        Text(
                          item.tanggal,
                          style: const TextStyle(
                              color: AppColors.gray500, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
