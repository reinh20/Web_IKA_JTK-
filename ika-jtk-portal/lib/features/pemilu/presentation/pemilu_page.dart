import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../auth/providers/auth_provider.dart';
import 'widgets/pemilu_faq_section.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../providers/pemilu_provider.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import 'widgets/candidate_poster_card.dart';
import 'widgets/countdown_timer.dart';
import 'widgets/election_cta_banner.dart';
import 'widgets/how_to_vote_section.dart';
import 'widgets/milestone_card.dart';
import 'widgets/stat_block.dart';

class PemiluPage extends ConsumerStatefulWidget {
  const PemiluPage({super.key});

  @override
  ConsumerState<PemiluPage> createState() => _PemiluPageState();
}

class _PemiluPageState extends ConsumerState<PemiluPage> {
  int _ctaTopVersion = 3; // 3 = Versi 3: Sesuai Konten (+ Margin) di paling atas

  final GlobalKey _kandidatKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _howToKey = GlobalKey();
  final GlobalKey _timelineKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  late final Map<String, GlobalKey> _sectionKeys = {
    'kandidat': _kandidatKey,
    'calon': _kandidatKey,
    'statistik': _statsKey,
    'stats': _statsKey,
    'howto': _howToKey,
    'carapilih': _howToKey,
    'timeline': _timelineKey,
    'jadwal': _timelineKey,
    'faq': _faqKey,
    'tanya': _faqKey,
    'cta': _ctaKey,
    'pilihkandidat': _ctaKey,
    'vote': _ctaKey,
  };

  String _lastScrolledSection = '';
  String _initialHash = '';

  @override
  void initState() {
    super.initState();
    // Tangkap hash secepat mungkin sebelum GoRouter/Flutter merubah URL
    try {
      _initialHash = html.window.location.hash.replaceAll('#', '').toLowerCase();
      if (_initialHash.isEmpty) {
        _initialHash = Uri.base.fragment.toLowerCase();
      }
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref.read(pemiluProvider.notifier).fetchElections(token: auth.token);
      _checkAndScrollToSection();
    });

    // Dengarkan perubahan hash pada URL saat link anchor diklik
    html.window.onHashChange.listen((_) {
      _checkAndScrollToSection(force: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Panggil secara sinkron agar Flutter mendaftarkan widget ini sebagai pendengar (listener)
    // terhadap perubahan URL/State dari GoRouter.
    String targetFromQuery = '';
    try {
      final uri = GoRouterState.of(context).uri;
      targetFromQuery = (uri.queryParameters['section'] ?? '').toLowerCase();
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndScrollToSection(queryTarget: targetFromQuery);
    });
  }

  void _checkAndScrollToSection({bool force = false, String? queryTarget}) {
    try {
      // Coba baca dari html.window.location.hash terlebih dahulu
      // karena GoRouter dan Uri.base kadang membuang (strip) fragment pada path strategy.
      var target = html.window.location.hash.replaceAll('#', '').toLowerCase();
      
      if (target.isEmpty) {
        target = Uri.base.fragment.toLowerCase();
      }
      
      // Baca dari query parameter murni (Uri.base) tanpa bergantung GoRouter
      var queryTargetValue = queryTarget ?? '';
      if (queryTargetValue.isEmpty) {
        queryTargetValue = (Uri.base.queryParameters['section'] ?? '').toLowerCase();
      }

      if (target.isEmpty && queryTargetValue.isNotEmpty) {
        target = queryTargetValue;
      }

      // Gunakan hash awal jika target saat ini kosong (efek GoRouter)
      if (target.isEmpty && _initialHash.isNotEmpty) {
        target = _initialHash;
      }
      
      if (target.isEmpty) return;
      if (!force && _lastScrolledSection == target) return;

      final targetKey = _sectionKeys[target];

      if (targetKey?.currentContext != null) {
        _lastScrolledSection = target;
        Scrollable.ensureVisible(
          targetKey!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );

        // Lakukan satu kali lagi setelah delay singkat untuk mengantisipasi layout shift (gambar loading, dsb)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && targetKey.currentContext != null) {
            Scrollable.ensureVisible(
              targetKey.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (_) {}
  }

  void scrollToSection(String sectionId) {
    html.window.history.pushState(null, '', '#$sectionId');
    html.window.dispatchEvent(html.Event('hashchange'));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      if (prev?.token != next.token &&
          next.token != null &&
          next.token!.isNotEmpty) {
        ref.read(pemiluProvider.notifier).fetchElections(token: next.token);
      }
    });

    ref.listen<PemiluState>(pemiluProvider, (prev, next) {
      if (prev?.isLoading == true && !next.isLoading) {
        String targetFromQuery = '';
        try {
          final uri = GoRouterState.of(context).uri;
          targetFromQuery = (uri.queryParameters['section'] ?? '').toLowerCase();
        } catch (_) {}

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndScrollToSection(force: true, queryTarget: targetFromQuery);
        });
      }
    });

    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final pemiluState = ref.watch(pemiluProvider);

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'pemilu')
              : const PublicAppBar(activeKey: 'pemilu'),
          _buildTopCtaBanner(),
          _buildHero(pemiluState),
          _buildCountdown(pemiluState),
          KeyedSubtree(key: _kandidatKey, child: _buildCandidates(pemiluState)),
          KeyedSubtree(key: _statsKey, child: _buildStats(pemiluState)),
          KeyedSubtree(key: _howToKey, child: _buildHowTo()),
          KeyedSubtree(key: _timelineKey, child: _buildTimeline(pemiluState)),
          KeyedSubtree(key: _faqKey, child: const PemiluFaqSection()),
          KeyedSubtree(key: _ctaKey, child: _buildCta()),
          const SiteFooter(),
        ],
      ),
    );
  }

  Widget _buildHero(PemiluState state) {
    final status = state.election?.status.toLowerCase() ?? '';
    final isNotStarted = status == 'draft' ||
        status == 'upcoming' ||
        status == 'scheduled' ||
        status == 'belum dimulai' ||
        (state.election?.periodeStart != null &&
            DateTime.now().isBefore(state.election!.periodeStart!));
    final isCompleted =
        status == 'completed' ||
        status == 'selesai' ||
        status == 'closed' ||
        (state.election?.votingEnd != null &&
            state.election!.votingEnd!.isBefore(DateTime.now()));
    final judul =
        state.election?.judul ?? 'Belum ada pemilu yang sedang berlangsung';
    final deskripsi =
        state.election?.deskripsi
            .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
            .trim() ??
        '';
    return SizedBox(
      height: 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1543269865-cbf427effbad?w=1600&q=60',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.navy),
          ),
          Container(color: Colors.black.withValues(alpha: 0.35)),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCompleted
                              ? 'PEMILU (TELAH SELESAI)'
                              : (isNotStarted ? 'PEMILU (BELUM DIMULAI)' : 'PEMILU'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          judul,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        if (deskripsi.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            deskripsi,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(PemiluState state) {
    if (state.election == null || state.election?.votingEnd == null) {
      return const SizedBox.shrink();
    }
    final status = state.election!.status.toLowerCase();
    final isDraft = status == 'draft' || status == 'draf';
    if (isDraft) {
      return const SizedBox.shrink();
    }
    final isNotStartedYet = status == 'upcoming' ||
        status == 'scheduled' ||
        status == 'belum dimulai' ||
        (state.election!.periodeStart != null &&
            DateTime.now().isBefore(state.election!.periodeStart!));
    if (!isNotStartedYet && state.election!.votingEnd != null && state.election!.votingEnd!.isBefore(DateTime.now())) {
      return const SizedBox.shrink();
    }
    final titleText = isNotStartedYet ? 'Waktu Menuju Dimulainya Pemilihan' : 'Batas Waktu Pemungutan Suara';
    final descText = isNotStartedYet
        ? 'Pemilihan belum resmi dibuka. Hitung mundur menuju waktu dimulainya pemungutan suara. Suara Anda sangat berarti bagi masa depan IKA JTK Polban.'
        : 'Pastikan Anda memberikan suara sebelum batas waktu berakhir. Suara Anda sangat berarti bagi masa depan IKA JTK Polban.';
    final timerDeadline = isNotStartedYet ? state.election!.periodeStart : state.election!.votingEnd;

    return SectionWrapper(
      backgroundColor: AppColors.peach,
      verticalPadding: 56,
      child: LayoutBuilder(
        builder: (context, c) {
          final isMobile = c.maxWidth < AppBreakpoints.tablet;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'HITUNG MUNDUR',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                titleText,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Container(width: 40, height: 3, color: AppColors.accent),
              const SizedBox(height: 12),
              Text(
                descText,
                style: const TextStyle(
                  color: AppColors.gray600,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          );
          final timer = CountdownTimer(
            deadline: timerDeadline,
            onFinished: () =>
                ref.read(pemiluProvider.notifier).fetchElections(),
          );
          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 24), timer],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: left),
              const SizedBox(width: 32),
              timer,
            ],
          );
        },
      ),
    );
  }

  Widget _buildCandidates(PemiluState state) {
    final candidates = state.candidates;
    return SectionWrapper(
      backgroundColor: Colors.white,
      verticalPadding: 56,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KANDIDAT',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kenali Para Calon Ketua IKA JTK Polban',
              style: TextStyle(
                color: AppColors.gray900,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 40, height: 3, color: AppColors.accent),
            const SizedBox(height: 12),
            const Text(
              'Baca ringkasan visi, misi, dan program kerja mereka — karena '
              'kepemimpinan yang tepat akan membawa IKA JTK Polban semakin solid '
              'dan relevan bagi seluruh alumni.',
              style: TextStyle(
                color: AppColors.gray600,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.how_to_vote_outlined,
                        size: 48,
                        color: AppColors.gray300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.election != null &&
                                (state.election!.status.toLowerCase() ==
                                        'completed' ||
                                    state.election!.status.toLowerCase() ==
                                        'selesai' ||
                                    state.election!.status.toLowerCase() ==
                                        'closed' ||
                                    (state.election!.votingEnd != null &&
                                        state.election!.votingEnd!.isBefore(
                                          DateTime.now(),
                                        )))
                            ? 'Pemilu "${state.election!.judul}" telah selesai dilaksanakan.'
                            : 'Belum ada pemilu yang sedang berlangsung.',
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, c) {
                  final isMobile = c.maxWidth < AppBreakpoints.tablet;
                  const gap = 24.0;
                  final perRow = isMobile ? 1 : 3;
                  final cardWidth = (c.maxWidth - gap * (perRow - 1)) / perRow;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final cand in candidates)
                        SizedBox(
                          width: cardWidth,
                          child: CandidatePosterCard(candidate: cand),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(PemiluState state) {
    if (state.election == null || state.election?.hideStatistik == true)
      return const SizedBox.shrink();
    final fmt = NumberFormat.decimalPattern('id');
    final totalAlumni = state.totalAlumniTerdaftar > 0
        ? state.totalAlumniTerdaftar
        : (state.activeSummary?.totalAlumniTerdaftar ?? 0);
    final voted = state.votingTotal;
    final percent = totalAlumni > 0 ? (voted / totalAlumni * 100).round() : 0;
    final diff =
        state.election?.votingEnd?.difference(DateTime.now()) ?? Duration.zero;
    final status = state.election?.status.toLowerCase() ?? '';
    final isNotStarted =
        status == 'draft' ||
        status == 'upcoming' ||
        status == 'scheduled' ||
        status == 'belum dimulai' ||
        (state.election?.periodeStart != null &&
            DateTime.now().isBefore(state.election!.periodeStart!));
    final isCompleted =
        status == 'completed' ||
        status == 'selesai' ||
        status == 'closed' ||
        (state.election?.votingEnd != null && state.election!.votingEnd!.isBefore(DateTime.now()));

    String sisaWaktuText = 'Selesai';
    String sisaWaktuLabel = 'Sisa Waktu Voting';
    if (isNotStarted) {
      sisaWaktuText = 'Belum Dimulai';
      sisaWaktuLabel = 'Status Voting';
    } else if (!isCompleted && state.election?.votingEnd != null) {
      final inDays = diff.inDays;
      final inHours = diff.inHours % 24;
      final inMinutes = diff.inMinutes % 60;

      if (inDays > 0) {
        sisaWaktuText = inHours > 0
            ? '$inDays Hari $inHours Jam'
            : '$inDays Hari';
      } else if (inHours > 0) {
        sisaWaktuText = inMinutes > 0
            ? '$inHours Jam $inMinutes Mnt'
            : '$inHours Jam';
      } else {
        sisaWaktuText = '$inMinutes Mnt';
      }
    }

    final linkWidget = InkWell(
      onTap: () => context.push('/pemilu/statistik'),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.only(bottom: 3),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white, width: 1.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Lihat Detail Statistik',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );

    return SectionWrapper(
      backgroundColor: const Color(0xFF1E293B),
      verticalPadding: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, c) {
            final isMobile = c.maxWidth < AppBreakpoints.tablet;

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATISTIK',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Statistik Pemilih Sementara',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 56, height: 3, color: AppColors.accent),
                  const SizedBox(height: 16),
                  linkWidget,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'STATISTIK',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                    linkWidget,
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Statistik Pemilih Sementara',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Container(width: 56, height: 3, color: AppColors.accent),
              ],
            );
          }),
          const SizedBox(height: 40),
          StatRow(
            items: [
              StatBlock(
                value: totalAlumni > 0 ? fmt.format(totalAlumni) : '1',
                label: 'Total Alumni Terdaftar',
              ),
              StatBlock(
                value: '${fmt.format(voted)} ($percent%)',
                label: 'Sudah Memilih',
              ),
              StatBlock(
                value: state.candidates.isNotEmpty ? state.candidates.length.toString() : '1',
                label: 'Jumlah Kandidat',
              ),
              StatBlock(value: sisaWaktuText, label: sisaWaktuLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowTo() {
    return SectionWrapper(
      verticalPadding: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TATA CARA',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bagaimana Cara Memberikan Suara?',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 40, height: 3, color: AppColors.accent),
          const SizedBox(height: 24),
          const HowToVoteSection(),
        ],
      ),
    );
  }

  Widget _buildTimeline(PemiluState state) {
    final election = state.election;
    final start = election?.periodeStart;
    final end = election?.votingEnd;
    final kandStart = election?.kandidatStart;
    final kandEnd = election?.kandidatEnd;
    final pengumumanDt = election?.pengumumanDate;
    final pelantikanDt = election?.pelantikanDate;

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    String formatSingleDate(DateTime dt) {
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    String formatDateRange(DateTime s, DateTime e) {
      if (s.year == e.year && s.month == e.month && s.day == e.day) {
        return '${s.day} ${months[s.month - 1]} ${s.year}';
      }
      if (s.year == e.year && s.month == e.month) {
        return '${s.day}-${e.day} ${months[e.month - 1]} ${e.year}';
      }
      if (s.year == e.year) {
        return '${s.day} ${months[s.month - 1]} - ${e.day} ${months[e.month - 1]} ${e.year}';
      }
      return '${s.day} ${months[s.month - 1]} ${s.year} - ${e.day} ${months[e.month - 1]} ${e.year}';
    }

    final List<MilestoneEntry> entries = [];

    if (start != null && end != null) {
      if (kandStart != null && kandEnd != null) {
        entries.add(
          MilestoneEntry(
            dateString: formatDateRange(kandStart, kandEnd),
            title: 'Pendaftaran & Verifikasi Kandidat',
          ),
        );
      }

      entries.add(
        MilestoneEntry(
          dateString: formatDateRange(start, end),
          title: 'Waktu Pemilihan',
        ),
      );

      if (pengumumanDt != null) {
        entries.add(
          MilestoneEntry(
            dateString: formatSingleDate(pengumumanDt),
            title: 'Pengumuman Hasil',
          ),
        );
      } else {
        final resDate = end.add(const Duration(days: 1));
        entries.add(
          MilestoneEntry(
            dateString:
                '${resDate.day} ${months[resDate.month - 1]} ${resDate.year}',
            title: 'Pengumuman Hasil',
          ),
        );
      }

      if (pelantikanDt != null) {
        entries.add(
          MilestoneEntry(
            dateString: formatSingleDate(pelantikanDt),
            title: 'Pelantikan Ketua Terpilih',
          ),
        );
      } else {
        final pelDate = end.add(const Duration(days: 14));
        entries.add(
          MilestoneEntry(
            dateString:
                '${pelDate.day} ${months[pelDate.month - 1]} ${pelDate.year}',
            title: 'Pelantikan Ketua Terpilih',
          ),
        );
      }
    } else {
      entries.addAll(const [
        MilestoneEntry(dateString: '2–6 Juli 2025', title: 'Waktu Pemilihan'),
        MilestoneEntry(dateString: '7 Juli 2025', title: 'Pengumuman Hasil'),
        MilestoneEntry(
          dateString: '20 Juli 2025',
          title: 'Pelantikan Ketua Terpilih',
        ),
      ]);
    }

    return SectionWrapper(
      backgroundColor: const Color(0xFFFAF7F2),
      verticalPadding: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIMELINE',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jadwal Lengkap Pemilu',
            style: const TextStyle(
              color: AppColors.gray900,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Berikut adalah tahapan penting yang akan dilalui dalam proses pemilu ini:',
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          Container(width: 40, height: 3, color: AppColors.accent),
          const SizedBox(height: 36),
          MilestoneRow(entries: entries),
        ],
      ),
    );
  }



  Widget _buildTopCtaBanner() {
    if (_ctaTopVersion == 0) return const SizedBox.shrink();
    final screenHeight = MediaQuery.of(context).size.height;
    final topBannerHeight = screenHeight > 300 ? screenHeight - 120 : 400.0;

    if (_ctaTopVersion == 1) {
      // Versi 1: Full Width, Tinggi Normal
      return SizedBox(
        width: double.infinity,
        height: 260,
        child: ElectionCtaBanner(
          height: 260,
          isFullBleed: true,
          borderRadius: 0,
        ),
      );
    } else if (_ctaTopVersion == 2) {
      // Versi 2: Tinggi Normal (260), Lebar Sesuai Konten (Max Width 1200 tanpa jarak vertikal)
      return SectionWrapper(
        verticalPadding: 0,
        child: SizedBox(
          height: 260,
          child: ElectionCtaBanner(
            height: 260,
          ),
        ),
      );
    } else if (_ctaTopVersion == 4) {
      // Versi 4: Full Height & Full Width tanpa ruang kosong
      return SizedBox(
        width: double.infinity,
        height: topBannerHeight,
        child: ElectionCtaBanner(
          height: topBannerHeight,
          isFullBleed: true,
          borderRadius: 0,
        ),
      );
    } else {
      // Versi 3: Sesuai Konten & Tinggi Normal di atas
      return const SectionWrapper(
        verticalPadding: 32,
        child: ElectionCtaBanner(),
      );
    }
  }

  Widget _buildCta() {
    if (_ctaTopVersion > 0) return const SizedBox.shrink();
    return const SectionWrapper(
      verticalPadding: 32,
      child: ElectionCtaBanner(),
    );
  }
}
