import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final Widget child;
  const ProfileSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: 160, height: 2, color: AppColors.accent),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class ProfileDataRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  const ProfileDataRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child:
                valueWidget ??
                Text(
                  value ?? '-',
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 13,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class ProfileTimelineRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;
  const ProfileTimelineRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null && trailing!.isNotEmpty) ...[
            const SizedBox(width: 16),
            Text(
              trailing!,
              style: const TextStyle(color: AppColors.gray500, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
