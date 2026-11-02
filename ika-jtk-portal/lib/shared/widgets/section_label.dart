import 'package:flutter/material.dart';
import '../../app/tokens.dart';

class SectionLabel extends StatelessWidget {
  final String label;
  final String title;
  final String? description;
  final Color labelColor;
  final Color titleColor;
  final Color underlineColor;
  final CrossAxisAlignment align;
  final double? maxWidth;

  const SectionLabel({
    super.key,
    required this.label,
    required this.title,
    this.description,
    this.labelColor = AppColors.primary,
    this.titleColor = AppColors.gray900,
    this.underlineColor = AppColors.accent,
    this.align = CrossAxisAlignment.start,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.stripHtml.toUpperCase(),
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title.stripHtml,
          style: TextStyle(
            color: titleColor,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: underlineColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth ?? 720),
            child: Text(
              description!.stripHtml,
              style: TextStyle(
                color: titleColor == Colors.white
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.gray600,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
