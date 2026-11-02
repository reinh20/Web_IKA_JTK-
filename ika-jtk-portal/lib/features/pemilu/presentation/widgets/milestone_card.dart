import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';

class MilestoneEntry {
  final DateTime? date;
  final String? dateString;
  final String title;
  final String description;
  const MilestoneEntry({
    this.date,
    this.dateString,
    required this.title,
    this.description = '',
  });
}

const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _getDateDisplay(MilestoneEntry entry) {
  if (entry.dateString != null && entry.dateString!.isNotEmpty) {
    return entry.dateString!;
  }
  if (entry.date != null) {
    return '${entry.date!.day} ${_months[entry.date!.month - 1]} ${entry.date!.year}';
  }
  return '';
}

class MilestoneCard extends StatelessWidget {
  final MilestoneEntry entry;
  const MilestoneCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getDateDisplay(entry),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            style: const TextStyle(
              color: AppColors.gray900,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.description,
              style: const TextStyle(
                color: AppColors.gray600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MilestoneRow extends StatelessWidget {
  final List<MilestoneEntry> entries;
  const MilestoneRow({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < AppBreakpoints.tablet;
        if (isMobile) {
          return Column(
            children: [
              for (var i = 0; i < entries.length; i++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 5),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (i < entries.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppColors.primary.withOpacity(0.35),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: i < entries.length - 1 ? 28 : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDateDisplay(entries[i]),
                                style: const TextStyle(
                                  color: AppColors.gray900,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entries[i].title,
                                style: const TextStyle(
                                  color: AppColors.gray500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                              if (entries[i].description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  entries[i].description,
                                  style: const TextStyle(
                                    color: AppColors.gray400,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < entries.length; i++)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDateDisplay(entries[i]),
                            style: const TextStyle(
                              color: AppColors.gray900,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entries[i].title,
                            style: const TextStyle(
                              color: AppColors.gray500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                          if (entries[i].description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              entries[i].description,
                              style: const TextStyle(
                                color: AppColors.gray400,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: AppColors.primary.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
