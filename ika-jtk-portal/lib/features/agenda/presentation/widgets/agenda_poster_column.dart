import 'package:flutter/material.dart';
import '../../../../core/portal_data.dart';
import 'agenda_row_card.dart';

class AgendaPosterColumn extends StatelessWidget {
  final List<AgendaContent> items;
  const AgendaPosterColumn({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          AgendaPosterCard(item: items[i]),
          if (i != items.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}
