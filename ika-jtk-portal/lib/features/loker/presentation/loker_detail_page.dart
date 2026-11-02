import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/tokens.dart';
import '../../../core/enums/alumni_status.dart';
import '../../../core/portal_data.dart';
import '../../../core/seo_helper.dart';
import '../../../shared/widgets/breadcrumb.dart';
import '../../../shared/widgets/html_content.dart';
import '../../../shared/widgets/portal_network_image.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/social_share_row.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../../member/providers/lamaran_provider.dart';
import '../providers/loker_provider.dart';
import 'widgets/loker_card.dart';

class LokerDetailPage extends ConsumerWidget {
  final String lokerId;
  const LokerDetailPage({super.key, required this.lokerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final allLoker = ref.watch(lokerProvider);
    final loker = allLoker.items.where((l) => l.id == lokerId).firstOrNull;

    if (loker == null) {
      return Scaffold(
        body: StickyFooterScrollView(children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'loker')
              : const PublicAppBar(activeKey: 'loker'),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Text(
                'Lowongan tidak ditemukan.',
                style: TextStyle(color: AppColors.gray500),
              ),
            ),
          ),
          const SiteFooter(),
        ]),
      );
    }

    SeoHelper.update(
      title: '${loker.posisi} - ${loker.namaPerusahaan}',
      description: loker.deskripsi,
      tags: loker.tags,
      imageUrl: loker.fullLogoUrl.isNotEmpty ? loker.fullLogoUrl : loker.logoUrl,
      type: 'article',
    );
    final related = allLoker.items.where((l) => l.id != lokerId).take(4).toList();

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'loker')
              : const PublicAppBar(activeKey: 'loker'),
          SectionWrapper(
            verticalPadding: 40,
            child: LayoutBuilder(
              builder: (context, c) {
                final isMobile = c.maxWidth < AppBreakpoints.tablet;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Breadcrumb(items: [
                      BreadcrumbItem(label: 'Beranda', onTap: () => context.go('/')),
                      BreadcrumbItem(label: 'Loker', onTap: () => context.go('/loker')),
                      const BreadcrumbItem(label: 'Detail'),
                    ]),
                    const SizedBox(height: 20),
                    _Header(loker: loker),
                    const SizedBox(height: 32),
                    Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isMobile ? 0 : 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HtmlContent(
                                html: loker.deskripsi,
                                fontSize: 14,
                              ),
                              if (loker.tags.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: loker.tags.split(',').where((t) => t.trim().isNotEmpty).map((t) => Container(
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
                              SocialShareRow(title: 'Lowongan: ${loker.posisi} di ${loker.namaPerusahaan}'),
                            ],
                          ),
                        ),
                        SizedBox(width: isMobile ? 0 : 40, height: isMobile ? 32 : 0),
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: _SidebarMeta(loker: loker),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (related.isNotEmpty)
            SectionWrapper(
              backgroundColor: AppColors.gray50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lowongan Lainnya',
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
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: related.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 1 : 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 128,
                            ),
                        itemBuilder: (_, i) => LokerCard(item: related[i]),
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

class _Header extends StatelessWidget {
  final LokerContent loker;
  const _Header({required this.loker});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompanyIcon(logoUrl: loker.fullLogoUrl.isNotEmpty ? loker.fullLogoUrl : loker.logoUrl, name: loker.namaPerusahaan),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loker.posisi,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(width: 40, height: 3, color: AppColors.accent),
              const SizedBox(height: 8),
              Text(
                _companyLine(),
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _companyLine() {
    final parts = [loker.namaPerusahaan, loker.kota]
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.join(' · ');
  }
}

class _SidebarMeta extends StatelessWidget {
  final LokerContent loker;
  const _SidebarMeta({required this.loker});

  @override
  Widget build(BuildContext context) {
    final tanggal = loker.dipostingTanggal;
    final authorLine = loker.authorNama.isEmpty
        ? '-'
        : (loker.authorRole.isNotEmpty
            ? '${loker.authorNama} (${loker.authorRole})'
            : loker.authorNama);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MetaLabel('Jenis Pekerjaan'),
        const SizedBox(height: 6),
        if (loker.jenisPekerjaan.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Pill(
              label: loker.jenisPekerjaan,
              bg: AppColors.primaryLight,
              fg: AppColors.primary,
            ),
          )
        else
          const Text('-', style: TextStyle(color: AppColors.gray500)),
        const SizedBox(height: 16),
        _MetaLabel('Lokasi'),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loker.tipeLokasi.isNotEmpty)
              Pill(
                label: loker.tipeLokasi,
                bg: AppColors.accentLight,
                fg: AppColors.accentDark,
              ),
            if (loker.tipeLokasi.isNotEmpty && loker.kota.isNotEmpty)
              const SizedBox(width: 8),
            if (loker.kota.isNotEmpty)
              Text(
                '· ${loker.kota}',
                style: const TextStyle(
                  color: AppColors.gray700,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _MetaLabel('Perusahaan'),
        const SizedBox(height: 6),
        Text(
          loker.namaPerusahaan.isEmpty ? '-' : loker.namaPerusahaan,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _MetaLabel('Diupload pada'),
        const SizedBox(height: 6),
        Text(
          tanggal.isEmpty ? '-' : tanggal,
          style: const TextStyle(color: AppColors.gray700, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _MetaLabel('Diupload Oleh'),
        const SizedBox(height: 6),
        Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 24,
                height: 24,
                child: PortalNetworkImage(
                  url: loker.authorAvatarUrl,
                  placeholderIcon: Icons.person_outline,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                authorLine,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ApplyActions(loker: loker),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        SocialShareRow(title: 'Lowongan: ${loker.posisi} di ${loker.namaPerusahaan}'),
      ],
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final String label;
  const _MetaLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.gray900,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ApplyActions extends ConsumerStatefulWidget {
  final LokerContent loker;
  const _ApplyActions({required this.loker});

  @override
  ConsumerState<_ApplyActions> createState() => _ApplyActionsState();
}

class _ApplyActionsState extends ConsumerState<_ApplyActions> {
  bool _isApplyingExternal = false;

  @override
  Widget build(BuildContext context) {
    final loker = widget.loker;
    final auth = ref.watch(authProvider);
    final loggedIn = auth.isLoggedIn;
    final user = auth.user;
    final verified = user != null &&
        (user.status == AlumniStatus.approved ||
            user.status == AlumniStatus.active);

    final lamaranState = ref.watch(lamaranProvider);
    final hasApplied =
        lamaranState.items.any((e) => e.lokerId == loker.id);

    Widget primary;
    if (hasApplied) {
      primary = ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 16),
        label: const Text(
          'Kamu sudah melamar pekerjaan ini',
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: AppColors.successBg,
          disabledForegroundColor: AppColors.success,
        ),
      );
    } else {
      primary = ElevatedButton.icon(
        onPressed: _isApplyingExternal ? null : () => _handleApply(loker, loggedIn, verified),
        icon: _isApplyingExternal
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward, size: 16),
        label: Text(
          !loggedIn
              ? 'Masuk untuk Melamar'
              : !verified
                  ? 'Akun Belum Terverifikasi'
                  : 'Lamar Sekarang',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primary,
        if (loggedIn) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/member/lamaran'),
            icon: const Icon(Icons.history, size: 16),
            label: const Text('Lihat Riwayat Lamaran'),
          ),
        ],
      ],
    );
  }

  Future<void> _handleApply(
    LokerContent loker,
    bool loggedIn,
    bool verified,
  ) async {
    if (!loggedIn) {
      context.go('/login');
      return;
    }
    if (!verified) return;

    if (loker.skemaPelamaran == 'external' && loker.linkExternal.isNotEmpty) {
      setState(() => _isApplyingExternal = true);
      try {
        await ref.read(lokerProvider.notifier).apply(loker.id, {});
        ref.read(lamaranProvider.notifier).fetchLamaran();
      } catch (e) {
        debugPrint('Gagal mencatat lamaran eksternal: $e');
      }

      var urlString = loker.linkExternal;
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
      final uri = Uri.parse(urlString);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka link eksternal')),
          );
        }
      } finally {
        if (mounted) setState(() => _isApplyingExternal = false);
      }
    } else {
      context.go('/loker/${loker.id}/apply');
    }
  }
}
