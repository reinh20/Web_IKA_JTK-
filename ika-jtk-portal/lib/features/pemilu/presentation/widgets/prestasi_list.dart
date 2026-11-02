import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_data.dart';

class PrestasiList extends StatelessWidget {
  final List<PrestasiItem> items;
  const PrestasiList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) _row(items[i], i == items.length - 1),
      ],
    );
  }

  Widget _row(PrestasiItem item, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : AppColors.gray100,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              item.text,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (item.year.isNotEmpty)
            Text(
              item.year,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
