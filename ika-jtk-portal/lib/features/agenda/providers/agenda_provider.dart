import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/app_config.dart';
import '../../../core/format_utils.dart';
import '../../../core/portal_data.dart';

/// Holds the agenda list together with a loading flag so the UI can tell
/// "still fetching" apart from "genuinely empty".
class AgendaState {
  final List<AgendaContent> items;
  final List<AgendaContent> heroItems;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String search;
  final String lokasi;
  final String waktuFilter;

  const AgendaState({
    this.items = const [],
    this.heroItems = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.search = '',
    this.lokasi = '',
    this.waktuFilter = 'Semua',
  });

  AgendaState copyWith({
    List<AgendaContent>? items,
    List<AgendaContent>? heroItems,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? search,
    String? lokasi,
    String? waktuFilter,
  }) {
    return AgendaState(
      items: items ?? this.items,
      heroItems: heroItems ?? this.heroItems,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      search: search ?? this.search,
      lokasi: lokasi ?? this.lokasi,
      waktuFilter: waktuFilter ?? this.waktuFilter,
    );
  }
}

class AgendaController extends StateNotifier<AgendaState> {
  AgendaController() : super(const AgendaState(isLoading: true)) {
    fetchAgenda();
  }

  String get baseUrl => AppConfig.apiBaseUrl;
  static const int _limit = 10;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  Future<void> fetchAgenda({
    bool loadMore = false,
    String? search,
    String? lokasi,
    String? waktuFilter,
  }) async {
    if (loadMore && (!state.hasMore || state.isLoadingMore)) return;

    final newSearch = search ?? state.search;
    final newLokasi = lokasi ?? state.lokasi;
    final newWaktuFilter = waktuFilter ?? state.waktuFilter;
    final nextPage = loadMore ? state.page + 1 : 1;

    state = state.copyWith(
      isLoading: !loadMore,
      isLoadingMore: loadMore,
      search: newSearch,
      lokasi: newLokasi,
      waktuFilter: newWaktuFilter,
      page: nextPage,
    );

    try {
      final upcomingQuery = newWaktuFilter == 'Upcoming' ? 'true' : (newWaktuFilter == 'Past' ? 'past' : 'false');
      final queryParams = {
        'page': nextPage.toString(),
        'limit': _limit.toString(),
        'upcoming': upcomingQuery,
        if (newSearch.isNotEmpty) 'search': newSearch,
        if (newLokasi.isNotEmpty) 'lokasi': newLokasi,
      };

      final uri = Uri.parse('$baseUrl/portal/agenda').replace(queryParameters: queryParams);
      final res = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        // Handle both response formats:
        // - Array langsung: [{...}, ...]
        // - Terbungkus: {"data": [{...}, ...]}
        final decoded = jsonDecode(res.body);
        final List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          data = (decoded['data'] as List?) ?? [];
        } else {
          data = [];
        }
        final items = data.map((e) {
          final tanggalEvent = e['tanggalEvent']?.toString() ?? '';
          final dt = DateTime.tryParse(tanggalEvent)?.toLocal();
          // Prefer an explicit `waktu` from the API; otherwise derive the time
          // from tanggalEvent (the CMS stores date & time together there).
          final explicitWaktu = e['waktu']?.toString().trim() ?? '';
          final waktu = explicitWaktu.isNotEmpty
              ? explicitWaktu
              : formatWaktu(tanggalEvent);
          final author = e['author'];
          final authorMap = author is Map ? author : const {};
          return AgendaContent(
            id: e['id']?.toString() ?? '',
            tanggal: dt?.day ?? 1,
            bulan: dt != null ? _months[dt.month - 1] : '',
            tahun: dt?.year.toString() ?? '',
            judul: e['judul']?.toString() ?? '',
            deskripsi: e['deskripsi']?.toString() ?? '',
            waktu: waktu,
            lokasi: e['lokasi']?.toString() ?? '',
            imageUrl: resolveImageUrl((e['bannerThumbnailUrl'] ?? e['bannerUrl'])?.toString()),
            fullImageUrl: resolveImageUrl(e['bannerUrl']?.toString()),
            authorNama: authorMap['nama']?.toString() ?? '',
            authorRole: authorMap['role']?.toString() ?? '',
            authorAvatarUrl: resolveImageUrl(authorMap['avatarUrl']?.toString(), fallbackName: authorMap['nama']?.toString()),
            publishedAt: e['publishedAt']?.toString() ?? '',
            tanggalEventRaw: tanggalEvent,
            tags: e['tags']?.toString() ?? '',
          );
        }).toList();

        final allItems = loadMore ? [...state.items, ...items] : items;
        List<AgendaContent> newHeroItems = state.heroItems;
        if ((newSearch.isEmpty && newLokasi.isEmpty && newWaktuFilter == 'Semua' && !loadMore) || state.heroItems.isEmpty) {
          final now = DateTime.now();
          final upcoming = allItems.where((a) {
            final dt = DateTime.tryParse(a.tanggalEventRaw);
            if (dt == null) return true;
            return dt.toLocal().isAfter(now);
          }).toList();
          upcoming.sort((a, b) {
            final da = DateTime.tryParse(a.tanggalEventRaw) ?? DateTime(2100);
            final db = DateTime.tryParse(b.tanggalEventRaw) ?? DateTime(2100);
            return da.compareTo(db);
          });
          newHeroItems = upcoming.take(3).toList();
          if (newHeroItems.isEmpty && allItems.isNotEmpty) {
            newHeroItems = allItems.take(3).toList();
          }
        }

        state = state.copyWith(
          items: allItems,
          heroItems: newHeroItems,
          isLoading: false,
          isLoadingMore: false,
          hasMore: items.length >= _limit,
        );
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, isLoadingMore: false);
    }
  }

  Future<Map<String, String>?> uploadBanner(List<int> fileBytes, String filename, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/general');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        fileBytes,
        filename: filename,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = (data['url'] ?? data['data']?['url'])?.toString() ?? '';
        final thumb = (data['thumbnailUrl'] ?? data['data']?['thumbnailUrl'] ?? data['thumbUrl'] ?? data['data']?['thumbUrl'])?.toString() ?? '';
        return {'url': url, 'thumbnailUrl': thumb};
      }
    } catch (_) {}
    return null;
  }

  Future<bool> submitAgenda({
    required String judul,
    required String deskripsi,
    required String tanggalEvent,
    required String waktu,
    required String lokasi,
    required String bannerUrl,
    required String token,
    String tags = '',
    String thumbnailUrl = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/portal/agenda'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'judul': judul,
          'deskripsi': deskripsi,
          'tanggalEvent': tanggalEvent,
          'waktu': waktu,
          'lokasi': lokasi,
          'bannerUrl': bannerUrl,
          'tags': tags,
          if (thumbnailUrl.isNotEmpty) 'bannerThumbnailUrl': thumbnailUrl,
        }),
      );
      if (res.statusCode == 201) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<String?> reservasiAgenda(String agendaId, String token) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/portal/agenda/$agendaId/reservasi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return null; // success
      }
      return data['error'] ?? 'Gagal melakukan reservasi';
    } catch (e) {
      return 'Terjadi kesalahan jaringan';
    }
  }
}

final agendaProvider = StateNotifierProvider<AgendaController, AgendaState>(
  (ref) => AgendaController(),
);
