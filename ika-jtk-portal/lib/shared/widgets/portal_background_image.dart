import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/tokens.dart';
import 'shimmer_placeholder.dart';

class PortalBackgroundImage extends StatelessWidget {
  final String imageUrl;
  final double alignmentX;
  final double alignmentY;
  final Color fallbackColor;

  const PortalBackgroundImage({
    super.key,
    required this.imageUrl,
    this.alignmentX = 50,
    this.alignmentY = 50,
    this.fallbackColor = AppColors.navy,
  });

  Alignment _alignment() {
    return Alignment(alignmentX / 50 - 1, alignmentY / 50 - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(color: fallbackColor);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      alignment: _alignment(),
      placeholder: (_, __) => const ShimmerPlaceholder(),
      errorWidget: (_, __, ___) => Container(color: fallbackColor),
    );
  }
}
