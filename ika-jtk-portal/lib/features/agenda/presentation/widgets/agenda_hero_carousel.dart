import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_data.dart';
import '../../../../shared/widgets/portal_network_image.dart';

class AgendaHeroCarousel extends StatefulWidget {
  final List<AgendaContent> items;
  const AgendaHeroCarousel({super.key, required this.items});

  @override
  State<AgendaHeroCarousel> createState() => _AgendaHeroCarouselState();
}

class _AgendaHeroCarouselState extends State<AgendaHeroCarousel> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < AppBreakpoints.tablet;
        final height = isMobile ? 520.0 : 380.0;
        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) =>
                    _HeroSlide(item: widget.items[i], isMobile: isMobile),
              ),
            ),
            if (widget.items.length > 1) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    GestureDetector(
                      onTap: () => _controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _current ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _current
                              ? AppColors.accent
                              : AppColors.gray300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final AgendaContent item;
  final bool isMobile;
  const _HeroSlide({required this.item, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AGENDA SELANJUTNYA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.judul,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoLine(
                    icon: Icons.calendar_today_outlined,
                    text: '${item.tanggal} ${item.bulan} ${item.tahun}',
                  ),
                  const SizedBox(height: 6),
                  _InfoLine(icon: Icons.access_time, text: item.waktu),
                  const SizedBox(height: 6),
                  _InfoLine(icon: Icons.place_outlined, text: item.lokasi),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/agenda/${item.id}'),
                    child: const Text('Lihat Detail Acara'),
                  ),
                ],
              ),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PortalNetworkImage(
              url: item.fullImageUrl,
              placeholderIcon: Icons.event_outlined,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.gray600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.gray700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
