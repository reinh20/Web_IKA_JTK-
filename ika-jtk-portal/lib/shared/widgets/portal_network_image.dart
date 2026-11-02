import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/tokens.dart';
import 'shimmer_placeholder.dart';

/// Network image that degrades gracefully:
/// - shows a neutral placeholder icon when the URL is empty, and
/// - shows the same placeholder (not a broken box) when loading fails.
///
/// Use this instead of a bare [CachedNetworkImage] so missing banners/logos
/// never render as an empty grey rectangle.
class PortalNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final IconData placeholderIcon;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? fallbackAsset;
  final double? width;
  final double? height;

  const PortalNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_outlined,
    this.backgroundColor,
    this.iconColor,
    this.fallbackAsset,
    this.width,
    this.height,
  });

  Widget _placeholder() {
    if (fallbackAsset != null && fallbackAsset!.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        color: backgroundColor ?? AppColors.gray200,
        alignment: Alignment.center,
        child: Image.asset(
          fallbackAsset!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _defaultPlaceholder(),
        ),
      );
    }
    return _defaultPlaceholder();
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.gray200,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: iconColor ?? AppColors.gray400, size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return _placeholder();
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => ShimmerPlaceholder(
        width: width,
        height: height,
        baseColor: backgroundColor ?? AppColors.gray200,
      ),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }
}
