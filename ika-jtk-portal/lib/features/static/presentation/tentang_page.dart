import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../../app/tokens.dart';
import '../../../core/portal_config_provider.dart';
import '../../../shared/widgets/portal_network_image.dart';
import '../../../shared/widgets/portal_background_image.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';

const _defaultOrganization = <OrganizationMember>[];

class TentangPage extends ConsumerWidget {
  const TentangPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final configState = ref.watch(portalConfigProvider);
    final config = configState.value;

    final about = config?.about;
    final title = about?.title ?? 'Ikatan Alumni Teknik Komputer POLBAN';
    final rawContent = (about?.content != null && about!.content.isNotEmpty)
        ? about.content
        : '<p>IKA JTK Polban adalah Ikatan para alumni lulusan dari jurusan Teknik Komputer Politeknik Negeri Bandung. IKA JTK merupakan wadah organisasi yang dapat menaungi dan memfasilitasi seluruh alumni JTK Polban, sehingga dapat menciptakan serta menjaga hubungan yang harmonis berdasarkan asas kekeluargaan dan kebersamaan antar alumni. IKA JTK juga dibentuk agar para alumni dapat bersinergi dan berkolaborasi untuk mencapai suatu tujuan tertentu. Selain itu, IKA JTK Polban terbentuk dari keinginan seluruh alumni yang ingin memberikan wadah komunikasi, silaturahmi, berbagi ilmu dan sarana lainnya yang bermanfaat untuk semua alumni JTK Polban.</p>';
    final orgList = (config?.organization != null && config!.organization.isNotEmpty)
        ? config.organization
        : _defaultOrganization;

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'tentang')
              : const PublicAppBar(activeKey: 'tentang'),
          SectionWrapper(
            verticalPadding: 48,
            maxContentWidth: 1100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TENTANG',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 40, height: 3, color: AppColors.accent),
                const SizedBox(height: 32),
                const _HeroBanner(),
                const SizedBox(height: 32),
                HtmlWidget(
                  rawContent,
                  textStyle: const TextStyle(
                    color: AppColors.gray700,
                    fontSize: 15,
                    height: 1.7,
                  ),
                  customStylesBuilder: (element) {
                    if (element.localName == 'a') {
                      return {'color': '#1E88E5', 'text-decoration': 'underline'};
                    }
                    if (element.localName == 'ol' || element.localName == 'ul') {
                      return {'padding-left': '20px'};
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          SectionWrapper(
            verticalPadding: 40,
            maxContentWidth: 1100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Struktur Organisasi',
                  style: TextStyle(
                    color: AppColors.gray900,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(width: 40, height: 3, color: AppColors.accent),
                const SizedBox(height: 32),
                orgList.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.groups_outlined,
                              size: 48,
                              color: AppColors.gray400,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Struktur organisasi masih belum dibuat',
                              style: TextStyle(
                                color: AppColors.gray700,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(builder: (context, c) {
                        int cols = 4;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orgList.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 32,
                            childAspectRatio: 0.7,
                          ),
                          itemBuilder: (_, i) => _PengurusCard(item: orgList[i]),
                        );
                      }),
              ],
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _HeroBanner extends ConsumerWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(portalConfigProvider).valueOrNull?.aboutBanner ?? const AboutBannerData();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 16 / 6,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (banner.imageUrl.isNotEmpty)
                  PortalBackgroundImage(
                    imageUrl: banner.imageUrl,
                    alignmentX: banner.bgImageX,
                    alignmentY: banner.bgImageY,
                    fallbackColor: AppColors.navy,
                  )
                else
                  PortalBackgroundImage(
                    imageUrl: '',
                    fallbackColor: AppColors.navy,
                  ),
                if (banner.showOverlay)
                  Container(
                    color: Color(int.parse(banner.overlayColor.replaceAll('#', '0xFF'))).withValues(alpha: banner.overlayOpacity / 100),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isMobile ? 16 : 24,
                      right: isMobile ? 16 : 32,
                    ),
                    child: _LogoContent(banner: banner),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isMobile ? 16 : 24,
                      left: isMobile ? 16 : 32,
                    ),
                    child: Text(
                      banner.tagline.isNotEmpty ? banner.tagline : 'Bersama, Berdampak.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogoContent extends ConsumerWidget {
  final AboutBannerData banner;
  const _LogoContent({required this.banner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lw = banner.logoWidth;
    final lh = banner.logoHeight;
    final configLogo = ref.watch(portalConfigProvider).valueOrNull?.logoUrl ?? '';
    final targetUrl = configLogo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              banner.headerLine1.isNotEmpty
                  ? banner.headerLine1
                  : 'JURUSAN TEKNIK KOMPUTER DAN INFORMATIKA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              banner.headerLine2.isNotEmpty
                  ? banner.headerLine2
                  : 'POLITEKNIK NEGERI BANDUNG',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: PortalNetworkImage(
            url: targetUrl,
            fallbackAsset: 'assets/images/logo.png',
            height: lh,
            width: lw,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _PengurusCard extends StatelessWidget {
  final OrganizationMember item;
  const _PengurusCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              child: PortalNetworkImage(
                url: item.imageUrl,
                fit: BoxFit.cover,
                placeholderIcon: Icons.person_outline,
                backgroundColor: AppColors.gray100,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item.nama,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${item.jabatan} / ${item.batch}',
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
