import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_data.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/html_content.dart';
import '../../../../shared/widgets/portal_network_image.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/section_wrapper.dart';
import '../../../agenda/providers/agenda_provider.dart';

class AgendaSection extends ConsumerWidget {
  const AgendaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaProvider);
    final sortedAgenda = List<AgendaContent>.from(agendaState.items);
    
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final upcomingOnly = sortedAgenda.where((a) {
      final dt = DateTime.tryParse(a.tanggalEventRaw);
      return dt == null || !dt.isBefore(today);
    }).toList();
    
    upcomingOnly.sort((a, b) {
      final dateA = DateTime.tryParse(a.tanggalEventRaw) ?? DateTime(0);
      final dateB = DateTime.tryParse(b.tanggalEventRaw) ?? DateTime(0);
      return dateA.compareTo(dateB);
    });

    final displayAgenda = upcomingOnly.take(5).toList();

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.tablet;

    return SectionWrapper(
      backgroundColor: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            label: 'Agenda',
            title: 'Acara & Agenda Alumni',
            description:
                'Jangan lewatkan acara-acara penting yang mempererat hubungan antar alumni Teknik Komputer POLBAN.',
            labelColor: AppColors.accent,
            titleColor: Colors.white,
          ),
          const SizedBox(height: 32),
          if (agendaState.isLoading && sortedAgenda.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (sortedAgenda.isEmpty)
            const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Belum ada agenda',
              message:
                  'Saat ini belum ada agenda yang dijadwalkan. Silakan cek kembali nanti.',
              onDark: true,
            )
          else
            Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isMobile ? 0 : 2,
                  child: Column(
                    children: displayAgenda
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _AgendaCard(item: a),
                            ))
                        .toList(),
                  ),
                ),
                SizedBox(width: isMobile ? 0 : 32, height: isMobile ? 24 : 0),
                Expanded(
                  flex: isMobile ? 0 : 1,
                  child: Column(
                    children: [
                      if (displayAgenda.isNotEmpty)
                        _AgendaPoster(
                          imageUrl: displayAgenda[0].imageUrl,
                          title: displayAgenda[0].judul,
                          onTap: () => context.go('/agenda/${displayAgenda[0].id}'),
                        ),
                      if (displayAgenda.length > 1) ...[
                        const SizedBox(height: 16),
                        _AgendaPoster(
                          imageUrl: displayAgenda[1].imageUrl,
                          title: displayAgenda[1].judul,
                          onTap: () => context.go('/agenda/${displayAgenda[1].id}'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => context.go('/agenda'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Lihat Semua Agenda'),
          ),
        ],
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final AgendaContent item;
  const _AgendaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/agenda/${item.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navyLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    item.tanggal.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.bulan} ${item.tahun}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: Colors.white.withValues(alpha: 0.15),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      children: [
                        if (item.waktu.trim().isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  size: 12, color: Colors.white.withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text(
                                item.waktu,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        if (item.lokasi.trim().isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.place_outlined,
                                  size: 12, color: Colors.white.withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text(
                                item.lokasi,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.deskripsi.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaPoster extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback? onTap;
  const _AgendaPoster({required this.imageUrl, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PortalNetworkImage(
              url: imageUrl,
              placeholderIcon: Icons.event_outlined,
              backgroundColor: AppColors.navyLight,
              iconColor: Colors.white,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
