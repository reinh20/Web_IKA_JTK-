import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/portal_data.dart';
import '../../../core/app_config.dart';
import '../../../core/format_utils.dart';

/// Helper: Parse tanggal dari PostgreSQL format 'YYYY-MM-DD HH:mm:ss'
/// maupun ISO 8601 'YYYY-MM-DDTHH:mm:ss'. DateTime.tryParse hanya
/// menerima format ISO, jadi spasi antara tanggal dan waktu diganti 'T'.
DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  // Jika format PostgreSQL "YYYY-MM-DD HH:mm:ss", ganti spasi ke-10 jadi 'T'
  final normalized = (s.length > 10 && s[10] == ' ')
      ? '${s.substring(0, 10)}T${s.substring(11)}'
      : s;
  return DateTime.tryParse(normalized);
}

class ElectionInfo {
  final String id;
  final String judul;
  final String deskripsi;
  final String status;
  final DateTime? votingEnd;
  final DateTime? periodeStart;
  final DateTime? kandidatStart;
  final DateTime? kandidatEnd;
  final DateTime? pengumumanDate;
  final DateTime? pelantikanDate;
  final DemographicsSummary? demographics;
  final bool hideStatistik;

  const ElectionInfo({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.status,
    this.votingEnd,
    this.periodeStart,
    this.kandidatStart,
    this.kandidatEnd,
    this.pengumumanDate,
    this.pelantikanDate,
    this.demographics,
    this.hideStatistik = false,
  });

  String get periodeLabel {
    if (periodeStart != null && votingEnd != null) {
      return '${periodeStart!.year}\u2013${votingEnd!.year}';
    }
    return '';
  }
}

class AngkatanStat {
  final String angkatan;
  final int count;
  const AngkatanStat({required this.angkatan, required this.count});
  factory AngkatanStat.fromJson(Map<String, dynamic> json) {
    return AngkatanStat(
      angkatan: json['angkatan']?.toString() ?? '',
      count: json['count'] is int ? json['count'] : (int.tryParse(json['count']?.toString() ?? '0') ?? 0),
    );
  }
}

class GenderStat {
  final String gender;
  final int count;
  final double persentase;
  const GenderStat({required this.gender, required this.count, required this.persentase});
  factory GenderStat.fromJson(Map<String, dynamic> json) {
    return GenderStat(
      gender: json['gender']?.toString() ?? '',
      count: json['count'] is int ? json['count'] : (int.tryParse(json['count']?.toString() ?? '0') ?? 0),
      persentase: (json['persentase'] is num ? json['persentase'] : 0.0).toDouble(),
    );
  }
}

class DemographicsSummary {
  final List<AngkatanStat> angkatan;
  final List<GenderStat> gender;
  const DemographicsSummary({required this.angkatan, required this.gender});
  factory DemographicsSummary.fromJson(Map<String, dynamic> json) {
    return DemographicsSummary(
      angkatan: (json['angkatan'] as List<dynamic>?)
              ?.map((e) => AngkatanStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gender: (json['gender'] as List<dynamic>?)
              ?.map((e) => GenderStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ElectionSummary {
  final String electionId;
  final String judul;
  final int totalSuara;
  final int totalAlumniTerdaftar;
  final List<SummaryCandidate> kandidat;
  final DemographicsSummary? demographics;

  const ElectionSummary({
    required this.electionId,
    required this.judul,
    required this.totalSuara,
    this.totalAlumniTerdaftar = 0,
    required this.kandidat,
    this.demographics,
  });

  factory ElectionSummary.fromJson(Map<String, dynamic> json) {
    return ElectionSummary(
      electionId: json['electionId']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      totalSuara: json['totalSuara'] is int
          ? json['totalSuara']
          : int.tryParse(json['totalSuara']?.toString() ?? '0') ?? 0,
      totalAlumniTerdaftar: json['totalAlumniTerdaftar'] is int
          ? json['totalAlumniTerdaftar']
          : int.tryParse(json['totalAlumniTerdaftar']?.toString() ?? '0') ?? 0,
      kandidat: (json['kandidat'] as List<dynamic>?)
              ?.map((e) => SummaryCandidate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      demographics: json['demographics'] != null
          ? DemographicsSummary.fromJson(json['demographics'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SummaryCandidate {
  final String id;
  final int nomorUrut;
  final String nama;
  final String? fotoUrl;
  final int voteCount;
  final double persentase;

  const SummaryCandidate({
    required this.id,
    required this.nomorUrut,
    required this.nama,
    this.fotoUrl,
    required this.voteCount,
    required this.persentase,
  });

  factory SummaryCandidate.fromJson(Map<String, dynamic> json) {
    return SummaryCandidate(
      id: json['id']?.toString() ?? '',
      nomorUrut: json['nomorUrut'] is int ? json['nomorUrut'] : 0,
      nama: json['nama']?.toString() ?? '',
      fotoUrl: resolveImageUrl(json['fotoUrl']?.toString(), fallbackName: json['nama']?.toString()),
      voteCount: json['voteCount'] is int ? json['voteCount'] : 0,
      persentase: (json['persentase'] is num ? json['persentase'] : 0.0).toDouble(),
    );
  }
}

class ElectionResult {
  final ElectionInfo election;
  final List<Candidate> candidates;
  final int totalSuara;
  final Candidate? winner;

  const ElectionResult({
    required this.election,
    required this.candidates,
    required this.totalSuara,
    this.winner,
  });
}

class PemiluState {
  final List<Candidate> candidates;
  final ElectionInfo? election;
  final bool isLoading;
  final String? error;
  final bool hasVoted;
  final int votingTotal;
  final int totalAlumniTerdaftar;
  final List<ElectionResult> completedElections;
  final ElectionSummary? activeSummary;
  final bool isSummaryLoading;

  const PemiluState({
    this.candidates = const [],
    this.election,
    this.isLoading = false,
    this.error,
    this.hasVoted = false,
    this.votingTotal = 0,
    this.totalAlumniTerdaftar = 0,
    this.completedElections = const [],
    this.activeSummary,
    this.isSummaryLoading = false,
  });

  PemiluState copyWith({
    List<Candidate>? candidates,
    ElectionInfo? election,
    bool? isLoading,
    String? error,
    bool? hasVoted,
    int? votingTotal,
    int? totalAlumniTerdaftar,
    List<ElectionResult>? completedElections,
    ElectionSummary? activeSummary,
    bool? isSummaryLoading,
    bool clearError = false,
    bool clearElection = false,
    bool clearActiveSummary = false,
  }) {
    return PemiluState(
      candidates: candidates ?? this.candidates,
      election: clearElection ? null : (election ?? this.election),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasVoted: hasVoted ?? this.hasVoted,
      votingTotal: votingTotal ?? this.votingTotal,
      totalAlumniTerdaftar: totalAlumniTerdaftar ?? this.totalAlumniTerdaftar,
      completedElections: completedElections ?? this.completedElections,
      activeSummary: clearActiveSummary ? null : (activeSummary ?? this.activeSummary),
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
    );
  }

  String get votingDeadline {
    if (election?.votingEnd != null) {
      return _formatDeadline(election!.votingEnd!);
    }
    return '-';
  }

  static String _formatDeadline(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    return '$day $month ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
  }
}

class PemiluController extends StateNotifier<PemiluState> {
  PemiluController() : super(const PemiluState()) {
    fetchElections();
  }

  String get baseUrl => AppConfig.apiBaseUrl;

  Future<void> fetchElections({String? token}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final res = await http.get(
        Uri.parse('$baseUrl/elections?_t=$timestamp'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final List<dynamic> elections = jsonDecode(res.body);

        ElectionInfo? activeElection;
        ElectionInfo? latestElection; // most recent election for timeline display
        List<Candidate> activeCandidates = [];
        int activeTotalSuara = 0;
        bool userHasVoted = false;
        int totalAlumniTerdaftar = 0;

        final List<ElectionResult> completed = [];

        for (final e in elections) {
          final status = e['status']?.toString() ?? '';
          final candidates = (e['candidates'] as List<dynamic>?)
                  ?.map(
                      (c) => Candidate.fromApiJson(c as Map<String, dynamic>))
                  .toList() ??
              [];

          candidates.sort((a, b) => a.nomorUrut.compareTo(b.nomorUrut));

          final totalSuara =
              candidates.fold<int>(0, (sum, c) => sum + c.voteCount);

          final rawTotalAlumni = e['totalAlumniTerdaftar'];
          if (rawTotalAlumni is int) {
            totalAlumniTerdaftar = rawTotalAlumni;
          } else if (rawTotalAlumni != null) {
            totalAlumniTerdaftar =
                int.tryParse(rawTotalAlumni.toString()) ?? totalAlumniTerdaftar;
          }

          final votingEnd = _parseDate(e['periodeEnd']);
          final startDt = _parseDate(e['periodeStart']);
          final kandidatStartDt = _parseDate(e['kandidatStart']);
          final kandidatEndDt = _parseDate(e['kandidatEnd']);
          final pengumumanDt = _parseDate(e['pengumumanDate']);
          final pelantikanDt = _parseDate(e['pelantikanDate']);

          // Pastikan judul selalu diperlakukan sebagai string,
          // bukan angka (cegah scientific notation seperti 1.11e+24)
          final judulRaw = e['judul'];
          final judul = judulRaw != null
              ? judulRaw.toString()
              : 'PEMILU IKA JTK';

          var effectiveStatus = status;
          final s = status.toLowerCase();
          if ((s == 'ongoing' || s == 'active' || s == 'sedang berlangsung') &&
              votingEnd != null &&
              votingEnd.isBefore(DateTime.now())) {
            effectiveStatus = 'Completed';
          } else if (s != 'ongoing' && s != 'active' && s != 'sedang berlangsung' && s != 'draft' && s != 'draf' && startDt != null && startDt.isAfter(DateTime.now())) {
            effectiveStatus = 'Upcoming';
          }

          final demoJson = e['demographics'];
          final parsedDemo = demoJson is Map<String, dynamic>
              ? DemographicsSummary.fromJson(demoJson)
              : null;

          final info = ElectionInfo(
            id: e['id']?.toString() ?? '',
            judul: judul,
            deskripsi: e['deskripsi']?.toString() ?? '',
            status: effectiveStatus,
            votingEnd: votingEnd,
            periodeStart: startDt,
            kandidatStart: kandidatStartDt,
            kandidatEnd: kandidatEndDt,
            pengumumanDate: pengumumanDt,
            pelantikanDate: pelantikanDt,
            demographics: parsedDemo,
            hideStatistik: e['hideStatistik'] == 1 || e['hideStatistik'] == true || e['hideStatistik'] == '1',
          );

          // Selalu simpan election terbaru untuk keperluan timeline
          latestElection = info;

          final effS = effectiveStatus.toLowerCase();
          if (effS == 'ongoing' || effS == 'active' || effS == 'sedang berlangsung') {
            activeElection = info;
            activeCandidates = candidates;
            activeTotalSuara = totalSuara;
            userHasVoted = e['userHasVoted'] == true;
          } else if (effS == 'completed' || effS == 'closed' || effS == 'selesai') {
            final sorted = List<Candidate>.from(candidates)
              ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
            final winner = sorted.isNotEmpty && sorted.first.voteCount > 0
                ? sorted.first
                : null;

            completed.add(ElectionResult(
              election: info,
              candidates: candidates,
              totalSuara: totalSuara,
              winner: winner,
            ));
          }
        }

        // Jika tidak ada pemilu aktif, gunakan pemilu terbaru untuk timeline
        final electionForTimeline = activeElection ?? latestElection;

        ElectionSummary? computedSummary;
        if (activeElection != null) {
          final summaryCandidates = activeCandidates.map((c) {
            final pct = activeTotalSuara > 0 ? (c.voteCount / activeTotalSuara) * 100.0 : 0.0;
            return SummaryCandidate(
              id: c.id,
              nomorUrut: c.nomorUrut,
              nama: c.nama,
              fotoUrl: c.fotoUrl,
              voteCount: c.voteCount,
              persentase: pct,
            );
          }).toList();
          computedSummary = ElectionSummary(
            electionId: activeElection.id,
            judul: activeElection.judul,
            totalSuara: activeTotalSuara,
            kandidat: summaryCandidates,
            demographics: activeElection.demographics,
          );
        }

        state = PemiluState(
          candidates: activeCandidates,
          election: electionForTimeline,
          hasVoted: userHasVoted,
          votingTotal: activeTotalSuara,
          totalAlumniTerdaftar: totalAlumniTerdaftar,
          activeSummary: computedSummary,
          completedElections: completed,
          isLoading: false,
        );

        if (electionForTimeline != null) {
          fetchSummary(token: token ?? '', electionId: electionForTimeline.id);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Gagal memuat data pemilu.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal terhubung ke server.',
      );
    }
  }

  Future<void> fetchSummary({required String token, required String electionId}) async {
    state = state.copyWith(isSummaryLoading: true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/elections/$electionId/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final summary = ElectionSummary.fromJson(data);
        state = state.copyWith(
          activeSummary: summary,
          totalAlumniTerdaftar: summary.totalAlumniTerdaftar >= 0
              ? summary.totalAlumniTerdaftar
              : state.totalAlumniTerdaftar,
          isSummaryLoading: false,
        );
      } else {
        state = state.copyWith(isSummaryLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isSummaryLoading: false);
    }
  }

  Future<String?> vote(String candidateId, String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/elections/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'candidateId': candidateId}),
      );

      if (res.statusCode == 200) {
        state = state.copyWith(isLoading: false, hasVoted: true);
        await fetchElections(token: token);
        return null;
      } else {
        try {
          final data = jsonDecode(res.body);
          final error = data['error']?.toString() ?? data['message']?.toString() ?? 'Gagal memberikan suara.';
          state = state.copyWith(isLoading: false, error: error);
          return error;
        } catch (_) {
          state = state.copyWith(isLoading: false, error: 'Server Error: ${res.statusCode}');
          return 'Server Error';
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal mengirim suara.');
      return 'Gagal mengirim suara.';
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final pemiluProvider =
    StateNotifierProvider<PemiluController, PemiluState>(
  (ref) {
    return PemiluController();
  },
);