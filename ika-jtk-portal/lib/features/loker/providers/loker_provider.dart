import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/app_config.dart';
import '../../../core/format_utils.dart';
import '../../../core/portal_data.dart';
import '../../auth/providers/auth_provider.dart';

class LokerState {
  final List<LokerContent> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String search;
  final String tipePekerjaan;
  final String sistemKerja;
  final String kota;

  const LokerState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.search = '',
    this.tipePekerjaan = 'Semua',
    this.sistemKerja = 'Semua Sistem',
    this.kota = 'Semua',
  });

  LokerState copyWith({
    List<LokerContent>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? search,
    String? tipePekerjaan,
    String? sistemKerja,
    String? kota,
  }) {
    return LokerState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      search: search ?? this.search,
      tipePekerjaan: tipePekerjaan ?? this.tipePekerjaan,
      sistemKerja: sistemKerja ?? this.sistemKerja,
      kota: kota ?? this.kota,
    );
  }
}

class LokerController extends StateNotifier<LokerState> {
  LokerController(this._ref) : super(const LokerState(isLoading: true)) {
    fetchLoker();
  }

  final Ref _ref;
  String get baseUrl => AppConfig.apiBaseUrl;
  static const int _limit = 10;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  Future<void> fetchLoker({
    bool loadMore = false,
    String? search,
    String? tipePekerjaan,
    String? sistemKerja,
    String? kota,
  }) async {
    if (loadMore && (!state.hasMore || state.isLoadingMore)) return;

    final newSearch = search ?? state.search;
    final newTipe = tipePekerjaan ?? state.tipePekerjaan;
    final newSistem = sistemKerja ?? state.sistemKerja;
    final newKota = kota ?? state.kota;
    final nextPage = loadMore ? state.page + 1 : 1;

    state = state.copyWith(
      isLoading: !loadMore,
      isLoadingMore: loadMore,
      search: newSearch,
      tipePekerjaan: newTipe,
      sistemKerja: newSistem,
      kota: newKota,
      page: nextPage,
    );

    try {
      final queryParams = {
        'page': nextPage.toString(),
        'limit': _limit.toString(),
        if (newSearch.trim().isNotEmpty) 'search': newSearch.trim(),
        if (newTipe != 'Semua Tipe' && newTipe != 'Semua' && newTipe.trim().isNotEmpty) ...{
          'jenisPekerjaan': newTipe,
          'tipePekerjaan': newTipe,
        },
        if (newSistem != 'Semua Sistem' && newSistem != 'Semua' && newSistem.trim().isNotEmpty) ...{
          'tipeLokasi': newSistem,
          'sistemKerja': newSistem,
        },
        if (newKota != 'Semua' && newKota.trim().isNotEmpty) 'kota': newKota,
      };

      final uri = Uri.parse('$baseUrl/portal/loker').replace(queryParameters: queryParams);
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
        final items = data.map((e) => _parseItem(e as Map<String, dynamic>)).toList();
        
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

  LokerContent? getById(String id) {
    try {
      return state.items.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  LokerContent _parseItem(Map<String, dynamic> e) {
    final createdAt = e['createdAt']?.toString() ?? '';
    final publishedAt = e['publishedAt']?.toString() ?? createdAt;
    final dipostingTanggal = formatTanggalWaktu(publishedAt);

    List<FormLamaranField> formLamaran = [];
    if (e['formLamaran'] is List) {
      formLamaran = (e['formLamaran'] as List)
          .map((f) => FormLamaranField.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    final author = e['author'] as Map<String, dynamic>? ?? {};

    return LokerContent(
      id: e['id']?.toString() ?? '',
      posisi: e['posisi']?.toString() ?? '',
      namaPerusahaan: e['namaPerusahaan']?.toString() ?? '',
      logoUrl: resolveImageUrl((e['logoThumbnailUrl'] ?? e['logoUrl'])?.toString()),
      fullLogoUrl: resolveImageUrl((e['logoUrl'] ?? e['logoThumbnailUrl'])?.toString()),
      jenisPekerjaan: e['jenisPekerjaan']?.toString() ?? '',
      tipeLokasi: e['tipeLokasi']?.toString() ?? '',
      kota: e['kota']?.toString() ?? '',
      deskripsi: e['deskripsi']?.toString() ?? '',
      skemaPelamaran: e['skemaPelamaran']?.toString() ?? 'internal',
      linkExternal: e['linkExternal']?.toString() ?? '',
      formLamaran: formLamaran,
      dipostingTanggal: dipostingTanggal,
      createdAtRaw: createdAt,
      authorNama: author['nama']?.toString() ?? '',
      authorRole: author['role']?.toString() ?? '',
      authorAvatarUrl: resolveImageUrl(author['avatarUrl']?.toString(), fallbackName: author['nama']?.toString()),
      tags: e['tags']?.toString() ?? '',
    );
  }

  Future<Map<String, dynamic>> apply(String lokerId, Map<String, dynamic> jawaban) async {
    final token = _ref.read(authProvider).token;
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final res = await http.post(
      Uri.parse('$baseUrl/portal/loker/$lokerId/apply'),
      headers: headers,
      body: jsonEncode({'jawaban': jawaban}),
    );

    if (res.statusCode == 200) {
      return {'success': true, 'message': 'Lamaran berhasil dikirim!'};
    }

    final body = jsonDecode(res.body);
    return {
      'success': false,
      'message': body['error']?.toString() ?? 'Gagal mengirim lamaran.',
    };
  }

  Future<Map<String, String>?> uploadFile(List<int> bytes, String filename) async {
    final token = _ref.read(authProvider).token;
    final uri = Uri.parse('$baseUrl/upload/general');
    final req = http.MultipartRequest('POST', uri);
    
    if (token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    try {
      final res = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode == 200) {
        final data = jsonDecode(body);
        final url = (data['url'] ?? data['data']?['url'])?.toString() ?? '';
        final thumb = (data['thumbnailUrl'] ?? data['data']?['thumbnailUrl'] ?? data['thumbUrl'] ?? data['data']?['thumbUrl'])?.toString() ?? '';
        return {'url': url, 'thumbnailUrl': thumb};
      }
    } catch (_) {}
    return null;
  }

  Future<bool> submitLoker({
    required String posisi,
    required String namaPerusahaan,
    required String websitePerusahaan,
    String logoUrl = '',
    required String jenisPekerjaan,
    required String tipeLokasi,
    required String kota,
    required String deskripsi,
    required String skemaPelamaran,
    String linkExternal = '',
    required List<Map<String, dynamic>> formLamaran,
    required String token,
    String tags = '',
    String logoThumbnailUrl = '',
  }) async {
    try {
      final body = <String, dynamic>{
        'posisi': posisi,
        'namaPerusahaan': namaPerusahaan,
        'websitePerusahaan': websitePerusahaan,
        'jenisPekerjaan': jenisPekerjaan,
        'tipeLokasi': tipeLokasi,
        'kota': kota,
        'deskripsi': deskripsi,
        'skemaPelamaran': skemaPelamaran,
        'tags': tags,
      };
      if (logoUrl.isNotEmpty) {
        body['logoUrl'] = logoUrl;
      }
      if (logoThumbnailUrl.isNotEmpty) {
        body['logoThumbnailUrl'] = logoThumbnailUrl;
      }
      if (skemaPelamaran == 'external') {
        body['linkExternal'] = linkExternal;
      }
      if (formLamaran.isNotEmpty) {
        body['formLamaran'] = formLamaran;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/portal/loker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final lokerProvider = StateNotifierProvider<LokerController, LokerState>(
  (ref) => LokerController(ref),
);
