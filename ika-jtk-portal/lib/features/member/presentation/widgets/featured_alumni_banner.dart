import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_data.dart';
import '../../../../shared/widgets/portal_network_image.dart';
import '../../../berita/providers/berita_provider.dart';

class FeaturedAlumniBanner extends ConsumerStatefulWidget {
  const FeaturedAlumniBanner({super.key});

  @override
  ConsumerState<FeaturedAlumniBanner> createState() =>
      _FeaturedAlumniBannerState();
}

class _FeaturedAlumniBannerState extends ConsumerState<FeaturedAlumniBanner> {
  int _index = 0;
  Timer? _timer;

  void _startTimer(int total) {
    _timer?.cancel();
    if (total <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % total);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredBeritaProvider);

    return featuredAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        _startTimer(list.length);
        final safeIndex = _index % list.length;
        final berita = list[safeIndex];

        return LayoutBuilder(
          builder: (context, c) {
            final isMobile = c.maxWidth < AppBreakpoints.tablet;
            final aspect = isMobile ? 4 / 3 : 16 / 9;
            return AspectRatio(
              aspectRatio: aspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: SizedBox.expand(
                      key: ValueKey(berita.id),
                      child: PortalNetworkImage(
                        url: berita.fullImageUrl,
                        placeholderIcon: Icons.image_outlined,
                        backgroundColor: AppColors.navy,
                        iconColor: Colors.white,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.25)),
                  Positioned(
                    left: isMobile ? 16 : 48,
                    bottom: isMobile ? 16 : 32,
                    right: isMobile ? 16 : null,
                    child: _OrangeOverlayCard(
                      berita: berita,
                      totalDots: list.length,
                      activeDot: safeIndex,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OrangeOverlayCard extends StatelessWidget {
  final BeritaContent berita;
  final int totalDots;
  final int activeDot;
  const _OrangeOverlayCard({
    required this.berita,
    required this.totalDots,
    required this.activeDot,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'HONORABLE ALUMNI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              berita.judul,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.go('/berita/${berita.id}'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Berita',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                ],
              ),
            ),
            if (berita.highlightedAlumni != null) ...[
              const SizedBox(height: 16),
              _AlumniMiniCard(alumni: berita.highlightedAlumni!),
            ],
            if (totalDots > 1) ...[
              const SizedBox(height: 16),
              _Dots(total: totalDots, active: activeDot),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlumniMiniCard extends StatelessWidget {
  final HighlightedAlumni alumni;
  const _AlumniMiniCard({required this.alumni});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 32,
              height: 32,
              child: PortalNetworkImage(
                url: alumni.avatarUrl,
                fit: BoxFit.cover,
                placeholderIcon: Icons.person_outline,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alumni.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (alumni.angkatan.isNotEmpty)
                  Text(
                    alumni.angkatan,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () => context.go('/member/alumni/${alumni.id}'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat Profile',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward, size: 12, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int total;
  final int active;
  const _Dots({required this.total, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == active;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
