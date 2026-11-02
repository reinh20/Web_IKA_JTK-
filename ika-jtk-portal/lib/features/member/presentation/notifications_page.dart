import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/tokens.dart';
import '../../../core/portal_data.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import 'widgets/member_app_bar.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = PortalData.notifications;
    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const MemberAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 40,
            maxContentWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(
                  label: 'Notifications',
                  title: 'Notifikasi',
                  description: 'Informasi terbaru dari IKA JTK Polban.',
                ),
                const SizedBox(height: 24),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotifTile(item: list[i]),
                ),
              ],
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationItem item;
  const _NotifTile({required this.item});

  IconData _iconFor(String tipe) {
    switch (tipe) {
      case 'berita':
        return Icons.newspaper_outlined;
      case 'agenda':
        return Icons.event_note_outlined;
      case 'lamaran':
        return Icons.work_outline;
      case 'pemilu':
        return Icons.how_to_vote_outlined;
      case 'profile':
        return Icons.person_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String tipe) {
    switch (tipe) {
      case 'berita':
        return AppColors.primary;
      case 'agenda':
        return AppColors.accent;
      case 'lamaran':
        return AppColors.success;
      case 'pemilu':
        return AppColors.navy;
      case 'profile':
        return AppColors.gray500;
      default:
        return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colorFor(item.tipe);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.read ? Colors.white : c.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: item.read ? AppColors.gray100 : c.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_iconFor(item.tipe), color: c, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: AppColors.gray900,
                          fontSize: 14,
                          fontWeight: item.read ? FontWeight.w600 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!item.read)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: AppColors.gray600,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.tanggal,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
