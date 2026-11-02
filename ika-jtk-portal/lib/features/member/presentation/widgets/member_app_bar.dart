import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_config_provider.dart';
import '../../../../core/format_utils.dart';
import '../../../../core/enums/alumni_status.dart';
import '../../../../shared/widgets/portal_network_image.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../pemilu/providers/pemilu_provider.dart';
import '../../providers/testimoni_provider.dart';

class MemberAppBar extends ConsumerStatefulWidget {
  final String activeKey;
  const MemberAppBar({super.key, this.activeKey = 'beranda'});

  @override
  ConsumerState<MemberAppBar> createState() => _MemberAppBarState();
}

class _MemberAppBarState extends ConsumerState<MemberAppBar> {
  final _menuKey = GlobalKey();
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final token = ref.read(authProvider).token;
      if (token != null && token.isNotEmpty) {
        ref.read(testimoniProvider.notifier).fetchMyTestimoni(token: token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final config = ref.watch(portalConfigProvider).valueOrNull;
    final pemiluState = ref.watch(pemiluProvider);
    
    final siteName = config?.siteName ?? 'IKA JTK POLBAN';
    final logoUrl = config?.logoUrl ?? '';
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

    final hasActivePemilu = pemiluState.election != null &&
        (pemiluState.election!.status == 'Ongoing' ||
            pemiluState.election!.status == 'Active');

    final menuItems = [
      const _NavItem('beranda', 'Beranda', '/member'),
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
        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 14,
      ),
      child: Row(
        children: [
          Row(
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
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          if (!isMobile)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: menuItems
                        .map(
                          (m) =>
                              _NavLink(item: m, active: m.key == widget.activeKey),
                        )
                        .toList(),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          if (isMobile) ...[
            _MobileNavMenu(items: menuItems, activeKey: widget.activeKey),
            const SizedBox(width: 8),
          ],
          _UserDropdown(
            key: _menuKey,
            user: auth.user,
            isOpen: _menuOpen,
            onToggle: () => setState(() => _menuOpen = !_menuOpen),
            onLogout: () {
              setState(() => _menuOpen = false);
              ref.read(authProvider.notifier).logout();
              context.go('/');
            },
            onProfile: () {
              setState(() => _menuOpen = false);
              context.go('/member/profile');
            },
          ),
        ],
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
                    fontWeight: widget.active
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.active)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -10,
                  child: Container(height: 2.5, color: AppColors.accent),
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

class _UserDropdown extends ConsumerWidget {
  final AlumniProfile? user;
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onLogout;
  final VoidCallback onProfile;

  const _UserDropdown({
    super.key,
    required this.user,
    required this.isOpen,
    required this.onToggle,
    required this.onLogout,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = user;
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;
    return PopupMenuButton<String>(
      tooltip: 'Menu pengguna',
      offset: const Offset(0, 16),
      position: PopupMenuPosition.under,
      color: Colors.white,
      elevation: 8,
      onOpened: () {
        // Setiap kali dropdown dibuka, cek ulang status testimoni dari server
        final token = ref.read(authProvider).token;
        if (token != null && token.isNotEmpty) {
          ref.read(testimoniProvider.notifier).fetchMyTestimoni(token: token);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.gray100),
      ),
      onSelected: (v) {
        if (v == 'data-alumni') GoRouter.of(context).go('/member/alumni');
        if (v == 'profile') onProfile();
        if (v == 'submit-konten' || v == 'beri-testimoni') {
          if (u != null && (u.status == AlumniStatus.approved || u.status == AlumniStatus.active)) {
            if (v == 'beri-testimoni') {
              // Check if latest testimoni is rejected and show snackbar
              final tState = ref.read(testimoniProvider);
              final myStatus = tState.myLatest?.status.toLowerCase() ?? '';
              if (myStatus == 'rejected') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFFEF2F2),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                    ),
                    content: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ((tState.myLatest?.rejectCount ?? 0) >= 3)
                                ? 'Silakan ajukan ulang testimoni baru.'
                                : (tState.myLatest?.rejectReason != null && tState.myLatest!.rejectReason!.isNotEmpty)
                                    ? 'Testimoni ditolak: ${tState.myLatest!.rejectReason}. (Maksimal 3 kali penolakan, setelahnya dapat dihapus oleh admin)'
                                    : 'Testimoni sebelumnya ditolak. Silakan ajukan testimoni baru. (Maksimal 3 kali penolakan, setelahnya dapat dihapus oleh admin)',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
            GoRouter.of(context).go(v == 'submit-konten' ? '/member/submit' : '/member/testimoni');
          } else {
            final isRejected = u?.status == AlumniStatus.rejected;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(isRejected ? 'Akun Ditolak' : 'Akses Ditolak'),
                content: Text(
                  isRejected
                      ? 'Verifikasi akun Anda ditolak oleh admin, sehingga Anda belum dapat mengirimkan konten atau testimoni. Silakan hubungi pengurus IKA JTK untuk informasi lebih lanjut.'
                      : 'Maaf, hanya alumni yang sudah terverifikasi (Disetujui Admin) yang dapat mengirimkan konten atau testimoni.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          }
        }
        if (v == 'logout') onLogout();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'data-alumni',
          height: 40,
          child: SizedBox(
            width: 200,
            child: Text(
              'Data Alumni',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'profile',
          height: 40,
          child: SizedBox(
            width: 200,
            child: Text(
              'Profil Saya',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'submit-konten',
          height: 40,
          child: SizedBox(
            width: 200,
            child: Text(
              'Submit Konten',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'beri-testimoni',
          height: 40,
          child: SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ref.watch(testimoniProvider).hasUnreadRejection)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  'Beri Testimoni',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ref.watch(testimoniProvider).hasUnreadRejection
                        ? AppColors.danger
                        : AppColors.gray800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'logout',
          height: 40,
          child: SizedBox(
            width: 200,
            child: Text(
              'Logout',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMobile) ...[
              Text(
                u?.nama ?? 'Pengguna',
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: u?.avatarUrl != null && u!.avatarUrl.isNotEmpty
                      ? Image.network(
                          key: ValueKey(u!.avatarUrl),
                          resolveThumbnailUrl(u.avatarUrl),
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _InitialsAvatar(name: u.nama),
                        )
                      : _InitialsAvatar(name: u?.nama ?? ''),
                ),
                if (ref.watch(testimoniProvider).hasUnreadRejection)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.gray700,
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      color: const Color(0xFFDDE8F5),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Color(0xFF1A3A5C),
          fontWeight: FontWeight.bold,
          fontSize: 14,
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
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
      onSelected: (route) => context.go(route),
      itemBuilder: (context) => items.map((m) {
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
      }).toList(),
    );
  }
}
