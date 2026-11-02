import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/app_config.dart';
import '../../../core/format_utils.dart';
import '../../../core/portal_data.dart';
import '../../../core/portal_config_provider.dart' show stripHtml;

/// Holds the berita list together with a loading flag so the UI can tell
/// "still fetching" apart from "genuinely empty".
class BeritaState {
  final List<BeritaContent> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String kategori;
  final String search;

  const BeritaState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.kategori = 'Semua',
    this.search = '',
  });

  BeritaState copyWith({
    List<BeritaContent>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? kategori,
    String? search,
  }) {
    return BeritaState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      kategori: kategori ?? this.kategori,
      search: search ?? this.search,
    );
  }
}

class BeritaController extends StateNotifier<BeritaState> {
  BeritaController() : super(const BeritaState(isLoading: true)) {
    fetchBerita();
  }

  String get baseUrl => AppConfig.apiBaseUrl;
  static const int _limit = 10;

  Future<void> fetchBerita({
    bool loadMore = false,
    String? kategori,
    String? search,
  }) async {
    if (loadMore && (!state.hasMore || state.isLoadingMore)) return;
    if (!loadMore && state.isLoading) {
      // Allow overriding search/kategori if forced, but usually we just want to load fresh.
    }

    final newKategori = kategori ?? state.kategori;
    final newSearch = search ?? state.search;
    final nextPage = loadMore ? state.page + 1 : 1;
    final filterChanged = !loadMore && (newKategori != state.kategori || newSearch != state.search);

    state = state.copyWith(
      items: filterChanged ? const [] : state.items,
      isLoading: !loadMore,
      isLoadingMore: loadMore,
      kategori: newKategori,
      search: newSearch,
      page: nextPage,
    );

    try {
      final queryParams = {
        'page': nextPage.toString(),
        'limit': _limit.toString(),
        if (newKategori != 'Semua') 'kategori': newKategori,
        if (newSearch.isNotEmpty) 'search': newSearch,
      };

      final uri = Uri.parse('$baseUrl/portal/berita').replace(queryParameters: queryParams);
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
        final items = data.map((e) => _parseBerita(e as Map<String, dynamic>)).toList();
        
        state = state.copyWith(
          items: loadMore ? [...state.items, ...items] : items,
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
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['error'] ?? data['message'] ?? 'Gagal mengunggah file');
        } catch (e) {
          throw Exception('Gagal mengunggah file (${response.statusCode})');
        }
      }
    } catch (e) {
      throw e;
    }
  }

  Future<bool> submitBerita(
    String judul,
    String konten,
    String bannerUrl,
    String kategori,
    String token, {
    String tags = '',
    String thumbnailUrl = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/portal/berita'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'judul': judul,
          'konten': konten,
          'bannerUrl': bannerUrl,
          'kategori': kategori,
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
}

final beritaProvider = StateNotifierProvider<BeritaController, BeritaState>(
  (ref) => BeritaController(),
);

BeritaContent _parseBerita(Map<String, dynamic> e) {
  final author = e['author'] as Map<String, dynamic>? ?? {};
  final highlighted = e['highlightedAlumni'] as Map<String, dynamic>?;
  return BeritaContent(
    id: e['id']?.toString() ?? '',
    judul: e['judul']?.toString() ?? '',
    excerpt: stripHtml(e['konten']?.toString() ?? ''),
    konten: e['konten']?.toString() ?? '',
    tanggal: formatTanggalWaktu(e['publishedAt']?.toString() ?? e['createdAt']?.toString()),
    imageUrl: resolveImageUrl((e['bannerThumbnailUrl'] ?? e['bannerUrl'])?.toString()),
    fullImageUrl: resolveImageUrl(e['bannerUrl']?.toString()),
    kategori: e['kategori']?.toString() ?? 'Pengumuman',
    authorId: author['id']?.toString() ?? '',
    authorNama: author['nama']?.toString() ?? '',
    authorRole: author['role']?.toString() ?? '',
    authorAvatarUrl: resolveImageUrl(author['avatarUrl']?.toString(), fallbackName: author['nama']?.toString()),
    tags: e['tags']?.toString() ?? '',
    highlightedAlumni: highlighted == null
        ? null
        : HighlightedAlumni(
            id: highlighted['id']?.toString() ?? '',
            nama: highlighted['nama']?.toString() ?? '',
            angkatan: highlighted['angkatan']?.toString() ?? '',
            avatarUrl: resolveImageUrl(highlighted['avatarUrl']?.toString(), fallbackName: highlighted['nama']?.toString()),
          ),
  );
}

final featuredBeritaProvider = FutureProvider.autoDispose<List<BeritaContent>>(
  (ref) async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/portal/berita?kategori=Alumni'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => _parseBerita(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const <BeritaContent>[];
  },
);

final heroBeritaProvider = FutureProvider.autoDispose<List<BeritaContent>>(
  (ref) async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/portal/berita?page=1&limit=5'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          data = (decoded['data'] as List?) ?? [];
        } else {
          data = [];
        }
        return data.map((e) => _parseBerita(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const <BeritaContent>[];
  },
);
