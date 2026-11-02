import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../providers/pemilu_provider.dart';
import 'widgets/stat_block.dart';

class PemiluStatistikPage extends ConsumerStatefulWidget {
  const PemiluStatistikPage({super.key});

  @override
  ConsumerState<PemiluStatistikPage> createState() => _PemiluStatistikPageState();
}

class _PemiluStatistikPageState extends ConsumerState<PemiluStatistikPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      final pemilu = ref.read(pemiluProvider);
      if (pemilu.election == null) {
        ref.read(pemiluProvider.notifier).fetchElections(token: auth.token);
      } else if (auth.token != null && auth.token!.isNotEmpty) {
        ref.read(pemiluProvider.notifier).fetchSummary(
              token: auth.token!,
              electionId: pemilu.election!.id,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final pemiluState = ref.watch(pemiluProvider);

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'statistik')
              : const PublicAppBar(activeKey: 'statistik'),
          _buildHeaderStats(context, pemiluState),
          _buildChartsSection(context, pemiluState),
          const SiteFooter(),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(BuildContext context, PemiluState state) {
    final fmt = NumberFormat.decimalPattern('id');
    final totalAlumni = state.totalAlumniTerdaftar > 0
        ? state.totalAlumniTerdaftar
        : (state.activeSummary?.totalAlumniTerdaftar ?? 0);
    int voted = 0;
    if (state.activeSummary != null && state.activeSummary!.totalSuara > 0) {
      voted = state.activeSummary!.totalSuara;
    } else if (state.votingTotal > 0) {
      voted = state.votingTotal;
    } else {
      voted = state.hasVoted ? 1 : 0;
    }
    final percent = totalAlumni > 0 ? ((voted / totalAlumni) * 100).round() : 0;

    String sisaWaktuText = '—';
    String sisaWaktuLabel = 'Sisa Waktu Voting';
    final el = state.election;
    if (el != null) {
      final status = el.status.toLowerCase();
      final isNotStarted = status == 'draft' ||
          status == 'upcoming' ||
          status == 'scheduled' ||
          status == 'belum dimulai' ||
          (el.periodeStart != null && DateTime.now().isBefore(el.periodeStart!));
      final isCompleted = status == 'completed' ||
          status == 'selesai' ||
          status == 'closed' ||
          (el.votingEnd != null && el.votingEnd!.isBefore(DateTime.now()));

      if (isNotStarted) {
        sisaWaktuText = 'Belum Dimulai';
        sisaWaktuLabel = 'Status Voting';
      } else if (isCompleted || el.votingEnd == null) {
        sisaWaktuText = 'Selesai';
      } else {
        final diff = el.votingEnd!.difference(DateTime.now());
        final inDays = diff.inDays;
        final inHours = diff.inHours % 24;
        final inMinutes = diff.inMinutes % 60;
        if (inDays > 0) {
          sisaWaktuText = '$inDays Hari $inHours Jam';
        } else if (inHours > 0) {
          sisaWaktuText = '$inHours Jam $inMinutes Mnt';
        } else if (inMinutes > 0) {
          sisaWaktuText = '$inMinutes Mnt';
        } else {
          sisaWaktuText = 'Selesai';
        }
      }
    }

    return SectionWrapper(
      backgroundColor: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/pemilu');
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Kembali ke Pemilu',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'STATISTIK',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Statistik Pemilih Sementara',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(width: 48, height: 4, color: AppColors.accent),
          const SizedBox(height: 32),
          StatRow(
            items: [
              StatBlock(
                value: fmt.format(totalAlumni),
                label: 'Total Alumni Terdaftar',
              ),
              StatBlock(
                value: '${fmt.format(voted)} ($percent%)',
                label: 'Sudah Memilih',
              ),
              StatBlock(
                value: state.candidates.length.toString(),
                label: 'Jumlah Kandidat',
              ),
              StatBlock(
                value: sisaWaktuText,
                label: sisaWaktuLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, PemiluState state) {
    if (state.election?.hideStatistik == true) {
      return SectionWrapper(
        backgroundColor: const Color(0xFFF8FAFC),
        verticalPadding: 64,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_off_outlined, size: 48, color: Color(0xFF64748B)),
                const SizedBox(height: 16),
                const Text(
                  'Data Statistik Disembunyikan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Panitia pemilu saat ini menyembunyikan tampilan statistik sementara.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final demo = state.activeSummary?.demographics;
    final isLoading = state.isSummaryLoading;

    final totalSuaraMasuk = state.activeSummary?.totalSuara ?? (state.votingTotal > 0 ? state.votingTotal : 0);
    final totalPemilihTerdaftar = state.totalAlumniTerdaftar > 0
        ? state.totalAlumniTerdaftar
        : (state.activeSummary?.totalAlumniTerdaftar ?? 0);

    List<SummaryCandidate> displayKandidat = state.activeSummary?.kandidat ?? [];
    if (displayKandidat.isEmpty && state.candidates.isNotEmpty) {
      displayKandidat = state.candidates.map((k) {
        final pct = totalSuaraMasuk > 0 ? (k.voteCount / totalSuaraMasuk * 100.0) : 0.0;
        return SummaryCandidate(
          id: k.id,
          nomorUrut: k.nomorUrut,
          nama: k.nama,
          fotoUrl: k.fotoUrl,
          voteCount: k.voteCount,
          persentase: pct,
        );
      }).toList();
    }
    displayKandidat.sort((a, b) => a.nomorUrut.compareTo(b.nomorUrut));

    // Siapkan data Angkatan dari data real server (demographics)
    final angkatanList = demo?.angkatan ?? state.election?.demographics?.angkatan ?? [];

    // Siapkan data Gender dari data real server (demographics)
    final genderList = demo?.gender ?? state.election?.demographics?.gender ?? [];

    return SectionWrapper(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('Memuat data statistik...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  _buildHasilSementaraSection(displayKandidat, totalSuaraMasuk, totalPemilihTerdaftar),
                  const SizedBox(height: 48),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 48),
                  _buildAngkatanChart(angkatanList),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 22, color: AppColors.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            totalSuaraMasuk > 0
                                ? 'Statistik di atas menampilkan sebaran angkatan dari alumni yang telah memvoting ($totalSuaraMasuk dari $totalPemilihTerdaftar pemilih terdaftar).'
                                : 'Grafik statistik sebaran angkatan baru akan muncul dan bertambah setelah ada alumni yang melakukan voting (0 dari $totalPemilihTerdaftar pemilih terdaftar).',
                            style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHasilSementaraSection(List<SummaryCandidate> kandidatList, int totalSuaraMasuk, int totalPemilihTerdaftar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hasil Sementara',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: 0.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_vote_rounded, size: 15, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Live Count',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 54,
          height: 3.5,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Total suara masuk: $totalSuaraMasuk dari $totalPemilihTerdaftar pemilih terdaftar',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        if (kandidatList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Belum ada data kandidat',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          Column(
            children: [
              for (final k in kandidatList) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${k.nomorUrut}. ${k.nama}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${k.voteCount} (${k.persentase.toStringAsFixed(k.persentase.truncateToDouble() == k.persentase ? 0 : 1)}%)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (k.persentase / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildAngkatanChart(List<AngkatanStat> data) {
    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'angkatan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            alignment: Alignment.center,
            child: const Text(
              'Belum ada grafik angkatan (akan bertambah setelah ada alumni yang memvoting).',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ),
        ],
      );
    }

    int maxCount = 0;
    for (var d in data) {
      if (d.count > maxCount) maxCount = d.count;
    }
    int gridMax = ((maxCount + 1) / 2).ceil() * 2;
    if (gridMax < 12) gridMax = 12;

    final colors = [
      const Color(0xFF5B629B),
      const Color(0xFF538D9E),
      const Color(0xFFCC8F52),
      const Color(0xFF90A4CE),
      const Color(0xFFD29F9B),
      const Color(0xFFB5D19F),
      const Color(0xFF3F69A8),
      const Color(0xFFC05252),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'angkatan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 360,
          child: CustomPaint(
            size: const Size(double.infinity, 360),
            painter: _AngkatanBarPainter(data: data, maxVal: gridMax, colors: colors),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < data.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors[i % colors.length].withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors[i % colors.length].withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Text(
                      'Angkatan ${data[i].angkatan}: ${data[i].count} orang',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors[i % colors.length]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AngkatanBarPainter extends CustomPainter {
  final List<AngkatanStat> data;
  final int maxVal;
  final List<Color> colors;

  _AngkatanBarPainter({required this.data, required this.maxVal, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;

    final textStyle = const TextStyle(color: Color(0xFF64748B), fontSize: 12);

    const double leftMargin = 34.0;
    const double bottomMargin = 34.0;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - bottomMargin;

    int step = 2;
    for (int v = 0; v <= maxVal; v += step) {
      final double y = chartHeight - (v / maxVal * chartHeight);
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), paintLine);

      final tp = TextPainter(
        text: TextSpan(text: '$v', style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 10, y - tp.height / 2));
    }

    if (data.isEmpty) return;

    final int count = data.length;
    final double barTotalAvailableWidth = chartWidth * 0.85;
    final double barWidth = math.min(110.0, barTotalAvailableWidth / count);
    final double startX = leftMargin + (chartWidth - (barWidth * count)) / 2;

    for (int i = 0; i < count; i++) {
      final double x = startX + (i * barWidth);
      final double barHeight = (data[i].count / maxVal) * chartHeight;
      final double y = chartHeight - barHeight;

      final paintBar = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), paintBar);

      final tpLabel = TextPainter(
        text: TextSpan(
          text: data[i].angkatan,
          style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      );
      tpLabel.layout();
      tpLabel.paint(
        canvas,
        Offset(x + (barWidth - tpLabel.width) / 2, chartHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AngkatanBarPainter oldDelegate) => true;
}
