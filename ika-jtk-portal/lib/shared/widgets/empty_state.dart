import 'package:flutter/material.dart';
import '../../app/tokens.dart';

/// Generic "no data yet" placeholder shown when a list is genuinely empty
/// (as opposed to still loading). Set [onDark] when placed on a dark section.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool onDark;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? Colors.white : AppColors.gray700;
    final messageColor =
        onDark ? Colors.white.withValues(alpha: 0.7) : AppColors.gray500;
    final iconColor =
        onDark ? Colors.white.withValues(alpha: 0.6) : AppColors.gray400;
    final borderColor =
        onDark ? Colors.white.withValues(alpha: 0.12) : AppColors.gray100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: messageColor,
            ),
          ),
        ],
      ),
    );
  }
}
