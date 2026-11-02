import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../app/tokens.dart';

class CandidateAvatar extends StatelessWidget {
  final String fotoUrl;
  final String nama;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isOval;

  const CandidateAvatar({
    super.key,
    required this.fotoUrl,
    required this.nama,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isOval = false,
  });

  @override
  Widget build(BuildContext context) {
    if (width != null && height != null) {
      return _buildSized(width!, height!);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w.isFinite && w > 0 && h.isFinite && h > 0) {
          return _buildSized(w, h);
        }
        return _buildSized(w > 0 ? w : 80, h > 0 ? h : 80);
      },
    );
  }

  Widget _buildSized(double w, double h) {
    Widget content;
    final url = fotoUrl.trim();

    if (url.isEmpty) {
      content = _buildInitials(w, h);
    } else {
      content = Image.network(
        url,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildInitials(w, h),
      );
    }

    if (isOval) {
      return ClipOval(child: content);
    }
    return SizedBox(width: w, height: h, child: content);
  }

  Widget _buildInitials(double w, double h) {
    final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    String initials = '??';
    if (parts.isNotEmpty) {
      if (parts.length == 1) {
        initials = parts[0][0].toUpperCase();
      } else {
        initials = (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      }
    }

    final colors = [
      AppColors.navy,
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF1E3A8A),
      const Color(0xFF0D9488),
      const Color(0xFF7C3AED),
    ];
    final idx = nama.codeUnits.fold<int>(0, (sum, char) => sum + char) % colors.length;
    final bg = colors[idx];

    final minDimension = w < h ? w : h;

    return Container(
      width: w,
      height: h,
      color: bg,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: minDimension * 0.38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
