import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/tokens.dart';
import '../../../core/portal_data.dart';
import '../../../core/seo_helper.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/html_content.dart';
import '../../../shared/widgets/portal_network_image.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/social_share_row.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/berita_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';

class BeritaDetailPage extends ConsumerWidget {
  final String beritaId;
  const BeritaDetailPage({super.key, required this.beritaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final beritaState = ref.watch(beritaProvider);
    final source = beritaState.items;

    if (beritaState.isLoading && source.isEmpty) {
      return Scaffold(
        body: StickyFooterScrollView(
          children: [
            loggedIn
                ? const MemberAppBar(activeKey: 'berita')
                : const PublicAppBar(activeKey: 'berita'),
            const SizedBox(height: 120),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 120),
            const SiteFooter(),
          ],
        ),
      );
    }

    BeritaContent? found;
    for (final b in source) {
      if (b.id == beritaId) {
        found = b;
        break;
      }
    }

    if (found == null) {
      return Scaffold(
        body: StickyFooterScrollView(
          children: [
            loggedIn
                ? const MemberAppBar(activeKey: 'berita')
                : const PublicAppBar(activeKey: 'berita'),
            SectionWrapper(
              verticalPadding: 64,
              child: Column(
                children: [
                  const EmptyState(
                    icon: Icons.article_outlined,
                    title: 'Berita tidak ditemukan',
                    message:
                        'Berita yang Anda cari tidak tersedia atau belum dipublikasikan.',
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => context.go('/berita'),
                    child: const Text('Kembali ke Berita'),
                  ),
                ],
              ),
            ),
            const SiteFooter(),
          ],
        ),
      );
    }

    final berita = found;
    SeoHelper.update(
      title: berita.judul,
      description: berita.excerpt,
      tags: berita.tags,
      imageUrl: berita.imageUrl,
      type: 'article',
    );
    final related = source.where((b) => b.id != beritaId).take(4).toList();

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'berita')
              : const PublicAppBar(activeKey: 'berita'),
          SectionWrapper(
            verticalPadding: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Breadcrumb(),
                const SizedBox(height: 20),
                Text(
                  berita.judul,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Container(width: 40, height: 3, color: AppColors.accent),
                const SizedBox(height: 16),
                _MetaRow(berita: berita),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PortalNetworkImage(
                      url: berita.fullImageUrl.isNotEmpty ? berita.fullImageUrl : berita.imageUrl,
                      placeholderIcon: Icons.article_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                HtmlContent(html: berita.konten, fontSize: 16),
                if (berita.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: berita.tags.split(',').where((t) => t.trim().isNotEmpty).map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '#${t.trim()}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 32),
                _ShareRow(berita: berita),
              ],
            ),
          ),
          SectionWrapper(
            backgroundColor: AppColors.gray50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Berita Lainnya',
                  style: TextStyle(
                    color: AppColors.gray900,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 40, height: 2, color: AppColors.accent),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final isMobile = c.maxWidth < AppBreakpoints.tablet;
                    if (related.isEmpty) {
                      return const Text(
                        'Belum ada berita lainnya',
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontSize: 13,
                        ),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: related.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 1 : 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 100,
                      ),
                      itemBuilder: (_, i) {
                        final r = related[i];
                        return InkWell(
                          onTap: () => context.go('/berita/${r.id}'),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.all(12),
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
                                    height: 72,
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: PortalNetworkImage(
                                        url: r.imageUrl,
                                        placeholderIcon: Icons.article_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        r.judul,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.gray900,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        r.tanggal,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.gray500,
                                        ),
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
                  },
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

class _Breadcrumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _crumb(context, label: 'BERANDA', onTap: () => context.go('/')),
        _sep(),
        _crumb(context, label: 'BERITA', onTap: () => context.go('/berita')),
        _sep(),
        _crumb(context, label: 'ARTICLE', onTap: null),
      ],
    );
  }

  Widget _crumb(BuildContext context,
      {required String label, required VoidCallback? onTap}) {
    final text = Text(
      label,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
    if (onTap == null) return text;
    return InkWell(onTap: onTap, child: text);
  }

  Widget _sep() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '/',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _MetaRow extends StatelessWidget {
  final BeritaContent berita;
  const _MetaRow({required this.berita});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_outlined,
              size: 14,
              color: AppColors.gray500,
            ),
            const SizedBox(width: 6),
            Text(
              'Diupload pada ${berita.tanggal}',
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: SizedBox(
                width: 24,
                height: 24,
                child: PortalNetworkImage(
                  url: berita.authorAvatarUrl,
                  placeholderIcon: Icons.person_outline,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              berita.authorRole.isNotEmpty
                  ? '${berita.authorNama} (${berita.authorRole})'
                  : berita.authorNama,
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  final BeritaContent berita;
  const _ShareRow({required this.berita});

  @override
  Widget build(BuildContext context) {
    return SocialShareRow(title: berita.judul);
  }
}

class _RelatedCard extends StatelessWidget {
  final BeritaContent item;
  const _RelatedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/berita/${item.id}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 140,
                child: PortalNetworkImage(
                  url: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.article_outlined,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            size: 12,
                            color: AppColors.gray500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Diupload pada ${item.tanggal}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                      if (item.excerpt.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
