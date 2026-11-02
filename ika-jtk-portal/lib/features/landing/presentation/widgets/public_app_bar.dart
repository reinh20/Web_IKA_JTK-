import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_config_provider.dart';
import '../../../../shared/widgets/portal_network_image.dart';
import '../../../pemilu/providers/pemilu_provider.dart';

class PublicAppBar extends ConsumerWidget {
  final String activeKey;
  const PublicAppBar({super.key, this.activeKey = 'beranda'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(portalConfigProvider).valueOrNull;
    final pemiluState = ref.watch(pemiluProvider);

    final siteName = config?.siteName ?? 'IKA JTK POLBAN';
    final logoUrl = config?.logoUrl ?? '';
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

    final hasActivePemilu = pemiluState.election != null &&
        (pemiluState.election!.status == 'Ongoing' ||
            pemiluState.election!.status == 'Active');

    final menuItems = [
      const _NavItem('beranda', 'Beranda', '/'),
      const _NavItem('berita', 'Berita', '/berita'),
      const _NavItem('agenda', 'Agenda', '/agenda'),
      const _NavItem('loker', 'Loker', '/loker'),
      const _NavItem('alumnigrafis', 'Alumni Grafis', '/alumnigrafis'),
      const _NavItem('tentang', 'Tentang', '/tentang'),
      _NavItem('pemilu', 'PEMILU', '/pemilu', hasDot: hasActivePemilu),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.gray100, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 14),
      child: Row(
        children: [
          _LogoBlock(siteName: siteName, logoUrl: logoUrl, onTap: () => context.go('/')),
          const SizedBox(width: 32),
          if (!isMobile)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: menuItems
                        .map((m) => _NavLink(item: m, active: m.key == activeKey))
                        .toList(),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          if (isMobile)
            _MobileNavMenu(items: menuItems, activeKey: activeKey)
          else ...[
            OutlinedButton(
              onPressed: () => context.go('/login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gray700,
                side: BorderSide(color: AppColors.gray200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Masuk'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => context.go('/register'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              label: const Text('Daftar'),
              icon: const Icon(Icons.arrow_forward, size: 16),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  final String siteName;
  final String logoUrl;
  final VoidCallback onTap;
  const _LogoBlock({required this.siteName, required this.logoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PortalNetworkImage(
              url: logoUrl,
              fallbackAsset: 'assets/images/logo.png',
              height: 48,
              width: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 15),
            Text(
              siteName,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 21,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String key;
  final String label;
  final String route;
  final bool hasDot;
  const _NavItem(this.key, this.label, this.route, {this.hasDot = false});
}

class _NavLink extends StatefulWidget {
  final _NavItem item;
  final bool active;
  const _NavLink({required this.item, required this.active});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.item.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: widget.active
                        ? AppColors.gray900
                        : (_hovered ? AppColors.gray900 : AppColors.gray600),
                    fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.active)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -10,
                  child: Container(
                    height: 2.5,
                    color: AppColors.accent,
                  ),
                ),
              if (widget.item.hasDot)
                Positioned(
                  right: -8,
                  top: 6,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
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

class _MobileNavMenu extends StatelessWidget {
  final List<_NavItem> items;
  final String activeKey;
  const _MobileNavMenu({required this.items, required this.activeKey});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu, size: 24, color: AppColors.gray800),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.gray100),
      ),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      onSelected: (route) => context.go(route),
      itemBuilder: (context) => [
        ...items.map((m) {
          final active = m.key == activeKey;
          return PopupMenuItem<String>(
            value: m.route,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  m.label,
                  style: TextStyle(
                    color: active ? AppColors.gray900 : AppColors.gray600,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (m.hasDot) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '/login',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: const Text(
            'Masuk',
            style: TextStyle(
              color: AppColors.gray700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: '/register',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: const [
              Text(
                'Daftar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}
