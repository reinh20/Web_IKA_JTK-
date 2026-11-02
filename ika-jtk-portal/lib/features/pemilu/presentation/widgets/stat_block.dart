import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';

class StatBlock {
  final String value;
  final String label;
  final Widget? topWidget;
  const StatBlock({required this.value, required this.label, this.topWidget});
}

class StatRow extends StatelessWidget {
  final List<StatBlock> items;
  final Widget? action;
  const StatRow({super.key, required this.items, this.action});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < AppBreakpoints.tablet;
        if (isMobile) {
          final cardWidth = ((c.maxWidth - 24) / 2).floorToDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 28,
                children: items.map((item) => SizedBox(
                  width: cardWidth,
                  child: _tile(item),
                )).toList(),
              ),
              if (action != null) ...[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(child: _tile(items[i])),
              if (i < items.length - 1) const SizedBox(width: 32),
            ],
            if (action != null) ...[
              const SizedBox(width: 32),
              action!,
            ],
          ],
        );
      },
    );
  }

  Widget _tile(StatBlock item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.topWidget != null) ...[
          item.topWidget!,
          const SizedBox(height: 16),
        ],
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -0.5,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}
