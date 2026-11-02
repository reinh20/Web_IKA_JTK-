import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_config_provider.dart';
import '../../../../shared/widgets/portal_network_image.dart';
import '../../../../shared/widgets/section_wrapper.dart';

class SiteFooter extends ConsumerWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(portalConfigProvider).valueOrNull;
    final siteName = config?.siteName ?? 'IKA JTK POLBAN';
    final contacts = config?.contacts ?? const ContactInfo();
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.tablet;

    return SectionWrapper(
      backgroundColor: AppColors.navy,
      verticalPadding: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isMobile ? 0 : 2,
                child: _Brand(
                  siteName: siteName,
                  tagline: config?.tagline ?? '',
                  logoUrl: config?.logoUrl ?? '',
                  contacts: contacts,
                ),
              ),
              SizedBox(width: 32, height: isMobile ? 32 : 0),
              Expanded(
                flex: isMobile ? 0 : 1,
                child: _LinkColumn(
                  title: 'Menu',
                  links: const [
                    _Link('Berita', '/berita'),
                    _Link('Agenda', '/agenda'),
                    _Link('Loker', '/loker'),
                    _Link('Tentang', '/tentang'),
                  ],
                ),
              ),
              SizedBox(width: 32, height: isMobile ? 32 : 0),
              Expanded(
                flex: isMobile ? 0 : 1,
                child: _LinkColumn(
                  title: 'Quick Links',
                  links: const [
                    _Link('Beranda', '/'),
                    _Link('Masuk/Buat Akun', '/login'),
                    // _Link('Kritik & Saran', '/kritik-saran'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2025, All Right Reserved',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final String siteName;
  final String tagline;
  final String logoUrl;
  final ContactInfo contacts;
  const _Brand({
    required this.siteName,
    required this.tagline,
    required this.logoUrl,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PortalNetworkImage(
              url: logoUrl,
              fallbackAsset: 'assets/images/logo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              siteName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          tagline.isNotEmpty ? tagline : 'Ikatan para alumni lulusan dari Jurusan Teknik Komputer dan Informatika Politeknik Negeri Bandung.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        _ContactRow(label: 'Contacts', isHeading: true),
        _ContactRow(label: 'Instagram : ${contacts.instagram}'),
        _ContactRow(label: 'Email : ${contacts.email}'),
        // if (contacts.whatsapp.isNotEmpty)
        //   _ContactRow(label: 'WhatsApp : ${contacts.whatsapp}'),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String label;
  final bool isHeading;
  const _ContactRow({required this.label, this.isHeading = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          color: isHeading
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.75),
          fontSize: isHeading ? 12 : 13,
          fontWeight: isHeading ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: isHeading ? 1 : 0,
        ),
      ),
    );
  }
}

class _Link {
  final String label;
  final String route;
  const _Link(this.label, this.route);
}

class _LinkColumn extends StatelessWidget {
  final String title;
  final List<_Link> links;
  const _LinkColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ...links.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => context.go(l.route),
              child: Text(
                l.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
