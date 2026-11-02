import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_data.dart';
import '../../../../shared/widgets/portal_network_image.dart';

class AgendaRowCard extends StatelessWidget {
  final AgendaContent item;
  final bool compact;
  final bool showThumbnail;
  const AgendaRowCard({
    super.key,
    required this.item,
    this.compact = false,
    this.showThumbnail = true,
  });

  @override
  Widget build(BuildContext context) {
    final badgeWidth = compact ? 56.0 : 64.0;
    final titleSize = compact ? 14.0 : 15.0;
    final thumbSize = compact ? 56.0 : 72.0;
    return InkWell(
      onTap: () => context.go('/agenda/${item.id}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: badgeWidth,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.gray100),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.tanggal.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: AppColors.gray900,
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.bulan} ${item.tahun}',
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                      fontSize: titleSize,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _MetaChip(icon: Icons.access_time, text: item.waktu),
                      _MetaChip(icon: Icons.place_outlined, text: item.lokasi),
                    ],
                  ),
                ],
              ),
            ),
            if (showThumbnail) ...[
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: thumbSize * 16 / 9,
                  height: thumbSize,
                  child: PortalNetworkImage(
                    url: item.imageUrl,
                    placeholderIcon: Icons.event_outlined,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.gray500),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.gray600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class AgendaPosterCard extends StatelessWidget {
  final AgendaContent item;
  const AgendaPosterCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/agenda/${item.id}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: PortalNetworkImage(
            url: item.imageUrl,
            placeholderIcon: Icons.event_outlined,
          ),
        ),
      ),
    );
  }
}
