import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/tokens.dart';
import '../../../core/enums/alumni_status.dart';
import '../../../core/format_utils.dart';
import '../../../core/portal_data.dart';
import '../../../core/seo_helper.dart';
import '../../../shared/widgets/breadcrumb.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/html_content.dart';
import '../../../shared/widgets/portal_network_image.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../providers/agenda_join_provider.dart';
import '../providers/agenda_provider.dart';
import 'widgets/agenda_row_card.dart';
import 'widgets/agenda_share_row.dart';

class AgendaDetailPage extends ConsumerWidget {
  final String agendaId;
  const AgendaDetailPage({super.key, required this.agendaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final agendaState = ref.watch(agendaProvider);
    final list = agendaState.items;

    if (agendaState.isLoading && list.isEmpty) {
      return Scaffold(
        body: StickyFooterScrollView(
          children: [
            loggedIn
                ? const MemberAppBar(activeKey: 'agenda')
                : const PublicAppBar(activeKey: 'agenda'),
            const SizedBox(height: 120),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 120),
            const SiteFooter(),
          ],
        ),
      );
    }

    AgendaContent? found;
    for (final a in list) {
      if (a.id == agendaId) {
        found = a;
        break;
      }
    }

    if (found == null) {
      return Scaffold(
        body: StickyFooterScrollView(
          children: [
            loggedIn
                ? const MemberAppBar(activeKey: 'agenda')
                : const PublicAppBar(activeKey: 'agenda'),
            SectionWrapper(
              verticalPadding: 64,
              child: Column(
                children: [
                  const EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'Agenda tidak ditemukan',
                    message:
                        'Agenda yang Anda cari tidak tersedia atau belum dipublikasikan.',
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => context.go('/agenda'),
                    child: const Text('Kembali ke Agenda'),
                  ),
                ],
              ),
            ),
            const SiteFooter(),
          ],
        ),
      );
    }

    final agenda = found;
    SeoHelper.update(
      title: agenda.judul,
      description: agenda.deskripsi,
      tags: agenda.tags,
      imageUrl: agenda.imageUrl,
      type: 'article',
    );
    final other = list.where((a) => a.id != agendaId).take(3).toList();

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'agenda')
              : const PublicAppBar(activeKey: 'agenda'),
          SectionWrapper(
            verticalPadding: 40,
            maxContentWidth: 1000,
            child: Builder(builder: (context) {
              final isMobile =
                  MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Breadcrumb(items: [
                    BreadcrumbItem(label: 'Beranda', onTap: () => context.go('/')),
                    BreadcrumbItem(label: 'Agenda', onTap: () => context.go('/agenda')),
                    const BreadcrumbItem(label: 'Detail'),
                  ]),
                  const SizedBox(height: 16),
                  Text(
                    agenda.judul,
                    style: const TextStyle(
                      color: AppColors.gray900,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 40, height: 3, color: AppColors.accent),
                  const SizedBox(height: 16),
                  _MetaRow(agenda: agenda),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: PortalNetworkImage(
                        url: agenda.fullImageUrl.isNotEmpty ? agenda.fullImageUrl : agenda.imageUrl,
                        placeholderIcon: Icons.event_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isMobile ? 0 : 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HtmlContent(
                              html: agenda.deskripsi,
                              fontSize: 15,
                            ),
                            if (agenda.tags.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: agenda.tags.split(',').where((t) => t.trim().isNotEmpty).map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    '#${t.trim()}',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ],
                            const SizedBox(height: 24),
                            AgendaShareRow(
                              agendaId: agenda.id,
                              judul: agenda.judul,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
                      Expanded(
                        flex: isMobile ? 0 : 1,
                        child: _DetailSidebar(agenda: agenda),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
          if (other.isNotEmpty)
            SectionWrapper(
              backgroundColor: AppColors.gray50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agenda Lainnya',
                    style: TextStyle(
                      color: AppColors.gray900,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(width: 32, height: 3, color: AppColors.accent),
                  const SizedBox(height: 24),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: other.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        AgendaRowCard(item: other[i], compact: true),
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

class _MetaRow extends StatelessWidget {
  final AgendaContent agenda;
  const _MetaRow({required this.agenda});

  @override
  Widget build(BuildContext context) {
    final publishedText = formatTanggalWaktu(agenda.publishedAt.isNotEmpty ? agenda.publishedAt : agenda.tanggalEventRaw);
    final hasPublished = publishedText.isNotEmpty;
    final hasAuthor = agenda.authorNama.isNotEmpty;
    if (!hasPublished && !hasAuthor) return const SizedBox.shrink();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        if (hasPublished)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.gray500),
              const SizedBox(width: 6),
              Text(
                'Diposting $publishedText',
                style: const TextStyle(
                  color: AppColors.gray600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        if (hasAuthor)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: agenda.authorAvatarUrl.isNotEmpty
                    ? NetworkImage(agenda.authorAvatarUrl)
                    : null,
                child: agenda.authorAvatarUrl.isEmpty
                    ? Text(
                        agenda.authorNama[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                agenda.authorNama,
                style: const TextStyle(
                  color: AppColors.gray700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DetailSidebar extends StatelessWidget {
  final AgendaContent agenda;
  const _DetailSidebar({required this.agenda});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _DetailRow(
            label: 'TANGGAL',
            value: '${agenda.tanggal} ${agenda.bulan} ${agenda.tahun}',
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'WAKTU',
            value: agenda.waktu.isNotEmpty ? agenda.waktu : 'Menyesuaikan',
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'LOKASI',
            value: agenda.lokasi.isNotEmpty ? agenda.lokasi : 'Akan diumumkan',
          ),
          const SizedBox(height: 20),
          _AgendaActions(agendaId: agenda.id),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AgendaActions extends ConsumerStatefulWidget {
  final String agendaId;
  const _AgendaActions({required this.agendaId});

  @override
  ConsumerState<_AgendaActions> createState() => _AgendaActionsState();
}

class _AgendaActionsState extends ConsumerState<_AgendaActions> {
  bool _isJoining = false;

  String _googleCalendarUrl(AgendaContent a) {
    final bulanMap = {
      'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
      'Mei': '05', 'Jun': '06', 'Jul': '07', 'Agu': '08',
      'Sep': '09', 'Okt': '10', 'Nov': '11', 'Des': '12',
    };
    final mm = bulanMap[a.bulan] ?? '01';
    final dd = a.tanggal.toString().padLeft(2, '0');
    final times = RegExp(r'(\d{2})\.(\d{2})').allMatches(a.waktu).toList();
    final startH = times.isNotEmpty ? times[0].group(1) : '09';
    final startM = times.isNotEmpty ? times[0].group(2) : '00';
    final endH = times.length > 1 ? times[1].group(1) : '17';
    final endM = times.length > 1 ? times[1].group(2) : '00';
    final startUtc = '${a.tahun}$mm${dd}T${_subHours(startH!, 7)}${startM}00Z';
    final endUtc = '${a.tahun}$mm${dd}T${_subHours(endH!, 7)}${endM}00Z';
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': a.judul,
      'details': a.deskripsi,
      'location': a.lokasi,
      'dates': '$startUtc/$endUtc',
    });
    return uri.toString();
  }

  String _subHours(String hh, int sub) {
    var h = int.parse(hh) - sub;
    if (h < 0) h += 24;
    return h.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final agendaId = widget.agendaId;
    final auth = ref.watch(authProvider);
    final loggedIn = auth.isLoggedIn;
    final joined = ref.watch(agendaJoinProvider).contains(agendaId);

    final list = ref.watch(agendaProvider).items;
    AgendaContent? found;
    for (final a in list) {
      if (a.id == agendaId) {
        found = a;
        break;
      }
    }
    if (found == null) return const SizedBox.shrink();
    final agenda = found;

    bool isPast = false;
    if (agenda.tanggalEventRaw.isNotEmpty) {
      final eventDate = DateTime.tryParse(agenda.tanggalEventRaw)?.toLocal();
      if (eventDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
        if (eventDay.isBefore(today)) {
          isPast = true;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final url = Uri.parse(_googleCalendarUrl(agenda));
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
          icon: const Icon(Icons.calendar_month, size: 16),
          label: const Text('Simpan di Kalender'),
        ),
        const SizedBox(height: 10),
        if (isPast)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.gray300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy, size: 14, color: AppColors.gray600),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'Agenda telah berlalu',
                    style: TextStyle(
                      color: AppColors.gray700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          )
        else if (loggedIn && (auth.user?.status == AlumniStatus.approved || auth.user?.status == AlumniStatus.active))
          joined
              ? ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successBg,
                    foregroundColor: AppColors.success,
                    elevation: 0,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Anda Sudah Terdaftar'),
                )
              : OutlinedButton.icon(
                  onPressed: _isJoining
                      ? null
                      : () async {
                          if (auth.token == null) return;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Konfirmasi Kehadiran'),
                              content: const Text('Apakah anda yakin ingin menghadiri acara ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Ya, Hadiri'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          setState(() => _isJoining = true);
                          final error = await ref
                              .read(agendaProvider.notifier)
                              .reservasiAgenda(agendaId, auth.token!);
                          if (!context.mounted) return;
                          setState(() => _isJoining = false);
                          if (error == null) {
                            ref.read(agendaJoinProvider.notifier).join(agendaId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reservasi berhasil! Detail acara telah dikirim ke email Anda.',
                                ),
                              ),
                            );
                          } else {
                            final isAlreadyJoined =
                                error.toLowerCase().contains('sudah terdaftar');
                            if (isAlreadyJoined) {
                              ref.read(agendaJoinProvider.notifier).join(agendaId);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: isAlreadyJoined
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                            );
                          }
                        },
                  icon: _isJoining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.event_available, size: 16),
                  label: const Text('Hadiri Acara'),
                )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    loggedIn
                        ? 'Hanya alumni terverifikasi yang dapat mendaftar agenda ini'
                        : 'Login untuk hadir acara ini',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
