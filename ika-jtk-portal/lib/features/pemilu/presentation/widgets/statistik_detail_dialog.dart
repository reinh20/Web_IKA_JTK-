import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/tokens.dart';
import '../../providers/pemilu_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class StatistikDetailDialog extends ConsumerStatefulWidget {
  final PemiluState state;
  const StatistikDetailDialog({super.key, required this.state});

  @override
  ConsumerState<StatistikDetailDialog> createState() => _StatistikDetailDialogState();
}

class _StatistikDetailDialogState extends ConsumerState<StatistikDetailDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      final el = widget.state.election;
      if (token != null && token.isNotEmpty && el != null) {
        ref.read(pemiluProvider.notifier).fetchSummary(token: token, electionId: el.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentState = ref.watch(pemiluProvider);
    final demo = currentState.activeSummary?.demographics;
    final isLoading = currentState.isSummaryLoading;

    final totalSuaraMasuk = currentState.activeSummary?.totalSuara ?? widget.state.votingTotal;
    final totalPemilihTerdaftar = widget.state.totalAlumniTerdaftar > 0
        ? widget.state.totalAlumniTerdaftar
        : (currentState.activeSummary?.totalAlumniTerdaftar ?? 0);

    List<SummaryCandidate> displayKandidat = currentState.activeSummary?.kandidat ?? [];
    if (displayKandidat.isEmpty && widget.state.candidates.isNotEmpty) {
      final kList = widget.state.candidates;
      displayKandidat = kList.map((k) {
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

    // Siapkan data Angkatan dari data real server
    final angkatanList = demo?.angkatan ?? widget.state.election?.demographics?.angkatan ?? [];
    // Siapkan data Gender dari data real server
    final genderList = demo?.gender ?? widget.state.election?.demographics?.gender ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 780),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Statistik Pemilih Sementara',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.state.election?.judul ?? 'Pemilu IKA JTK',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 28, color: AppColors.navy),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text('Memuat data statistik...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHasilSementaraSection(displayKandidat, totalSuaraMasuk, totalPemilihTerdaftar),
                          const SizedBox(height: 36),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 36),
                          _buildAngkatanChart(angkatanList),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            // Footer Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      totalSuaraMasuk > 0
                          ? 'Statistik di atas menampilkan sebaran angkatan dari alumni yang telah memvoting ($totalSuaraMasuk dari $totalPemilihTerdaftar pemilih terdaftar).'
                          : 'Grafik statistik sebaran angkatan baru akan muncul dan bertambah setelah ada alumni yang melakukan voting (0 dari $totalPemilihTerdaftar pemilih terdaftar).',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
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
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: 0.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_vote_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Live Count',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Total suara masuk: $totalSuaraMasuk dari $totalPemilihTerdaftar pemilih terdaftar',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        if (kandidatList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
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
                          fontSize: 14,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
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
                const SizedBox(height: 18),
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
        const SizedBox(height: 24),
        SizedBox(
          height: 320,
          child: CustomPaint(
            size: const Size(double.infinity, 320),
            painter: _AngkatanBarPainter(data: data, maxVal: gridMax, colors: colors),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < data.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors[i % colors.length].withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors[i % colors.length].withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(
                      'Angkatan ${data[i].angkatan}: ${data[i].count} orang',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors[i % colors.length]),
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

    final textStyle = const TextStyle(color: Color(0xFF64748B), fontSize: 11);

    const double leftMargin = 30.0;
    const double bottomMargin = 30.0;
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
      tp.paint(canvas, Offset(leftMargin - tp.width - 8, y - tp.height / 2));
    }

    if (data.isEmpty) return;

    final int count = data.length;
    final double barTotalAvailableWidth = chartWidth * 0.85;
    final double barWidth = math.min(100.0, barTotalAvailableWidth / count);
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
          style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      );
      tpLabel.layout();
      tpLabel.paint(
        canvas,
        Offset(x + (barWidth - tpLabel.width) / 2, chartHeight + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
