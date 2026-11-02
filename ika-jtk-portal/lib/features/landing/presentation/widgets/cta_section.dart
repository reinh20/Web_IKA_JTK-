import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../shared/widgets/portal_network_image.dart';

class CtaSection extends StatelessWidget {
  final bool showButton;
  const CtaSection({super.key, this.showButton = true});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.tablet;
    final tileHeight = isMobile ? 200.0 : 320.0;

    return SizedBox(
      height: tileHeight,
      child: isMobile
          ? _CtaMobile(tileHeight: tileHeight, showButton: showButton)
          : _CtaDesktop(tileHeight: tileHeight, showButton: showButton),
    );
  }
}

class _CtaDesktop extends StatelessWidget {
  final double tileHeight;
  final bool showButton;
  const _CtaDesktop({required this.tileHeight, required this.showButton});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Tile(
            imageUrl:
                'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=900&q=80',
          ),
        ),
        Expanded(
          child: _Tile(
            imageUrl:
                'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=900&q=80',
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: tileHeight,
            color: AppColors.accent,
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gabung Bersama Komunitas\nAlumni',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dapatkan manfaat jejaring alumni, info lowongan kerja, dan acara alumni terkini.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (showButton) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accent,
                    ),
                    child: const Text('Gabung Sekarang'),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: _Tile(
            imageUrl:
                'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=900&q=80',
          ),
        ),
      ],
    );
  }
}

class _CtaMobile extends StatelessWidget {
  final double tileHeight;
  final bool showButton;
  const _CtaMobile({required this.tileHeight, required this.showButton});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tileHeight,
      color: AppColors.accent,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gabung Bersama Komunitas Alumni',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dapatkan manfaat jejaring alumni, info lowongan kerja, dan acara alumni terkini.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (showButton) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accent,
              ),
              child: const Text('Gabung Sekarang'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String imageUrl;
  const _Tile({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return PortalNetworkImage(
      url: imageUrl,
      fit: BoxFit.cover,
      backgroundColor: AppColors.gray300,
    );
  }
}
