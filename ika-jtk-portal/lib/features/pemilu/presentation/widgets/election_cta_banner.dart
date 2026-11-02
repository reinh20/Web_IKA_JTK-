import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';

class ElectionCtaBanner extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final String targetRoute;
  final double? height;
  final bool isFullBleed;
  final double? borderRadius;

  const ElectionCtaBanner({
    super.key,
    this.title = 'Siap Menentukan Masa Depan IKA JTK?',
    this.description =
        'Jika kamu merasa yakin dengan pilihanmu, saatnya untuk berpartisipasi dan berikan suaramu sekarang.',
    this.buttonLabel = 'Pilih Sekarang',
    this.targetRoute = '/pemilu/vote',
    this.height,
    this.isFullBleed = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < AppBreakpoints.tablet;
    final content = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: (height ?? 360) * 0.55, child: _imageStack()),
              Expanded(child: _orangePanel(context)),
            ],
          )
        : SizedBox(
            height: height ?? 260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _imageStack()),
                Expanded(flex: 4, child: _orangePanel(context)),
              ],
            ),
          );

    final widgetContent = height != null && isMobile
        ? SizedBox(height: height, child: content)
        : content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        borderRadius ?? (isFullBleed ? 0 : AppRadius.lg),
      ),
      child: widgetContent,
    );
  }

  Widget _imageStack() {
    return Container(
      color: AppColors.gray800,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1540910419892-4a36d2c3266c?w=800&q=60',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.gray800,
              alignment: Alignment.center,
              child: const Icon(
                Icons.how_to_vote,
                color: Colors.white24,
                size: 64,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.25)),
        ],
      ),
    );
  }

  Widget _orangePanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      color: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(targetRoute),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
