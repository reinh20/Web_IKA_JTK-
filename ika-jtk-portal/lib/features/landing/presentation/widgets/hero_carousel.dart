import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_config_provider.dart';
import '../../../../shared/widgets/portal_background_image.dart';

class HeroCarousel extends ConsumerStatefulWidget {
  const HeroCarousel({super.key});

  @override
  ConsumerState<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<HeroCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleTimer();
  }

  void _scheduleTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;
      final slides = ref.read(portalConfigProvider).valueOrNull?.heroSlides ?? [];
      if (slides.isEmpty) return;
      final next = (_current + 1) % slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawSlides = ref.watch(portalConfigProvider).valueOrNull?.heroSlides ?? [];
    final slides = rawSlides.isEmpty
        ? const [
            HeroSlide(
              imageUrl: '',
              overlayTitle: 'Selamat Datang di Portal IKA JTK POLBAN',
              newsTitle: 'Wadah Komunikasi & Kolaborasi Alumni JTK POLBAN',
              newsExcerpt:
                  'Hubungkan kembali jejaring alumni, ikuti agenda kegiatan terbaru, serta temukan peluang karir profesional di ekosistem IKA JTK.',
              badgeLabel: 'INFO ALUMNI',
              showOverlay: true,
            )
          ]
        : rawSlides;

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.tablet;
    final height = isMobile ? 380.0 : width * (13 / 36);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: slides.length,
            itemBuilder: (_, i) => _Slide(slide: slides[i], isMobile: isMobile),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == _current;
                return GestureDetector(
                  onTap: () => _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final HeroSlide slide;
  final bool isMobile;
  const _Slide({required this.slide, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PortalBackgroundImage(
          imageUrl: slide.imageUrl,
          alignmentX: slide.bgImageX,
          alignmentY: slide.bgImageY,
          fallbackColor: AppColors.navy,
        ),
        if (slide.showOverlay)
          Builder(builder: (_) {
            final hex = slide.overlayColor.replaceFirst('#', '');
            Color c = const Color(0xFF1E2A4D);
            if (hex.length == 6) {
              final r = int.tryParse(hex.substring(0, 2), radix: 16) ?? 0x1E;
              final g = int.tryParse(hex.substring(2, 4), radix: 16) ?? 0x2A;
              final b = int.tryParse(hex.substring(4, 6), radix: 16) ?? 0x4D;
              c = Color.fromRGBO(r, g, b, 1.0);
            }
            return Container(color: c.withValues(alpha: slide.overlayOpacity / 100));
          }),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final titleFontSize = isMobile ? 32.0 : (w * 0.04).clamp(32.0, 56.0);
          final newsWidth = isMobile ? double.infinity : (w * 0.42).clamp(360.0, 480.0);
          final cardPad = isMobile ? 16.0 : (w * 0.014).clamp(16.0, 22.0);
          final newsTitleSize = isMobile ? 18.0 : (w * 0.016).clamp(18.0, 22.0);
          final newsExcerptSize = isMobile ? 13.0 : (w * 0.011).clamp(13.0, 15.0);
          final badgeSize = 11.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: isMobile ? 24 : (w * 0.05).clamp(24.0, 80.0),
                top: isMobile ? 40 : (h * 0.15).clamp(40.0, 80.0),
                child: SizedBox(
                  width: (w * 0.55).clamp(320.0, 750.0),
                  child: Text(
                    slide.overlayTitle,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: const Color(0xFF1B4332),
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: isMobile ? 16 : (w * 0.035).clamp(20.0, 48.0),
                bottom: isMobile ? 24 : (h * 0.12).clamp(24.0, 48.0),
                right: isMobile ? 16 : null,
                child: Container(
                  width: newsWidth,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(cardPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          slide.badgeLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: badgeSize,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        slide.newsTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: newsTitleSize,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        slide.newsExcerpt,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: newsExcerptSize,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
