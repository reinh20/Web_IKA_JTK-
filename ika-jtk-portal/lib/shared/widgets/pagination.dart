import 'package:flutter/material.dart';
import '../../app/tokens.dart';

class Pagination extends StatelessWidget {
  final int totalPages;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  const Pagination({
    super.key,
    required this.totalPages,
    required this.currentPage,
    required this.onPageChanged,
  });

  List<Object> _buildPages() {
    if (totalPages <= 7) {
      return List<int>.generate(totalPages, (i) => i + 1);
    }
    final pages = <Object>[];
    pages.add(1);
    if (currentPage > 4) pages.add('...');
    final start = (currentPage - 1).clamp(2, totalPages - 3);
    final end = (currentPage + 1).clamp(4, totalPages - 1);
    for (int i = start; i <= end; i++) {
      pages.add(i);
    }
    if (currentPage < totalPages - 3) pages.add('...');
    pages.add(totalPages - 1);
    pages.add(totalPages);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        _NavButton(
          icon: Icons.arrow_back,
          label: 'Previous',
          isForward: false,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        ..._buildPages().map((p) {
          if (p is int) {
            final active = p == currentPage;
            return _PageNumber(
              page: p,
              active: active,
              onTap: active ? null : () => onPageChanged(p),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
          );
        }),
        _NavButton(
          icon: Icons.arrow_forward,
          label: 'Next',
          isForward: true,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}

class _PageNumber extends StatelessWidget {
  final int page;
  final bool active;
  final VoidCallback? onTap;
  const _PageNumber({
    required this.page,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.gray900 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: active ? Colors.white : AppColors.gray700,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isForward;
  final bool enabled;
  final VoidCallback onTap;
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isForward,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.gray700 : AppColors.gray300;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isForward
              ? [
                  Text(label, style: TextStyle(color: color, fontSize: 13)),
                  const SizedBox(width: 4),
                  Icon(icon, size: 14, color: color),
                ]
              : [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(label, style: TextStyle(color: color, fontSize: 13)),
                ],
        ),
      ),
    );
  }
}
