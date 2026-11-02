import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/app_config.dart';
import '../../../core/portal_data.dart';
import '../../auth/providers/auth_provider.dart';

/// Holds the alumni list together with a loading flag so the UI can tell
/// "still fetching" apart from "genuinely empty".
class AlumniState {
  final List<AlumniDirEntry> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String search;
  final String angkatan;
  final List<String> angkatanOpts;
  final int total;

  const AlumniState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.search = '',
    this.angkatan = 'Semua',
    this.angkatanOpts = const ['Semua'],
    this.total = 0,
  });

  AlumniState copyWith({
    List<AlumniDirEntry>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? search,
    String? angkatan,
    List<String>? angkatanOpts,
    int? total,
  }) {
    return AlumniState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      search: search ?? this.search,
      angkatan: angkatan ?? this.angkatan,
      angkatanOpts: angkatanOpts ?? this.angkatanOpts,
      total: total ?? this.total,
    );
  }
}

class AlumniController extends StateNotifier<AlumniState> {
  AlumniController(this._ref, {this.hasGrafis = false}) : super(const AlumniState(isLoading: true)) {
    fetchAlumni();
  }

  final Ref _ref;
  final bool hasGrafis;
  String get baseUrl => AppConfig.apiBaseUrl;
  static const int _limit = 12;

  Future<void> fetchAlumni({
    bool loadMore = false,
    String? search,
    String? angkatan,
  }) async {
    if (loadMore && (!state.hasMore || state.isLoadingMore)) return;

    final newSearch = search ?? state.search;
    final newAngkatan = angkatan ?? state.angkatan;
    final nextPage = loadMore ? state.page + 1 : 1;

    state = state.copyWith(
      isLoading: !loadMore,
      isLoadingMore: loadMore,
      search: newSearch,
      angkatan: newAngkatan,
      page: nextPage,
    );

    try {
      final token = _ref.read(authProvider).token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('$baseUrl/portal/alumni').replace(queryParameters: {
        'page': nextPage.toString(),
        'limit': _limit.toString(),
        if (newSearch.isNotEmpty) 'search': newSearch,
        if (newAngkatan != 'Semua') 'angkatan': newAngkatan,
        if (hasGrafis) 'hasGrafis': 'true',
      });

      final res = await http.get(
        uri,
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data.containsKey('data')) {
           final items = (data['data'] as List)
               .map((e) => AlumniDirEntry.fromJson(e as Map<String, dynamic>))
               .toList();
           final angkatanOpts = ['Semua', ...List<String>.from(data['angkatanOpts'] ?? [])];
           
           state = state.copyWith(
             items: loadMore ? [...state.items, ...items] : items,
             isLoading: false,
             isLoadingMore: false,
             hasMore: items.length >= _limit,
             total: data['total'],
             angkatanOpts: angkatanOpts,
           );
        } else if (data is List) {
           final items = data
               .map((e) => AlumniDirEntry.fromJson(e as Map<String, dynamic>))
               .where((item) => !hasGrafis || (item.alumniGrafis != null && (item.alumniGrafis!['status']?.toString().toUpperCase() ?? '') == 'APPROVED'))
               .toList();
           state = state.copyWith(
             items: loadMore ? [...state.items, ...items] : items,
             isLoading: false,
             isLoadingMore: false,
             hasMore: items.length >= _limit,
           );
        } else {
           state = state.copyWith(isLoading: false, isLoadingMore: false);
        }
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, isLoadingMore: false);
    }
  }

  Future<Map<String, dynamic>?> getDetail(String id) async {
    try {
      final token = _ref.read(authProvider).token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final res = await http.get(
        Uri.parse('$baseUrl/portal/alumni/$id'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
            return body['data'] as Map<String, dynamic>;
          }
          return body;
        }
      }
    } catch (_) {}
    return null;
  }
}

final alumniProvider = StateNotifierProvider<AlumniController, AlumniState>(
  (ref) => AlumniController(ref),
);

final alumniGrafisProvider = StateNotifierProvider<AlumniController, AlumniState>((ref) {
  return AlumniController(ref, hasGrafis: true);
});
