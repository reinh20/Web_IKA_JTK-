import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../../core/app_config.dart';
import '../../../core/portal_data.dart';

class LamaranState {
  final List<LamaranEntry> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const LamaranState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  LamaranState copyWith({
    List<LamaranEntry>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return LamaranState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error, // Can be null intentionally
    );
  }
}

class LamaranController extends StateNotifier<LamaranState> {
  final Ref _ref;
  static const int _limit = 10;

  LamaranController(this._ref) : super(const LamaranState(isLoading: true)) {
    fetchLamaran();
  }

  Future<void> fetchLamaran({bool loadMore = false}) async {
    if (loadMore && (!state.hasMore || state.isLoadingMore)) return;
    
    final nextPage = loadMore ? state.page + 1 : 1;

    state = state.copyWith(
      isLoading: !loadMore,
      isLoadingMore: loadMore,
      page: nextPage,
      error: null,
    );

    final token = _ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(isLoading: false, isLoadingMore: false);
      return;
    }

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/portal/lamaran').replace(queryParameters: {
        'page': nextPage.toString(),
        'limit': _limit.toString(),
      });
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
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
        final items = data.map((e) => LamaranEntry(
          id: e['id'] ?? '',
          lokerId: e['lokerId'] ?? '',
          posisi: e['posisi'] ?? '',
          perusahaan: e['perusahaan'] ?? '',
          logoUrl: (e['logoUrl']?.toString() ?? '').startsWith('/')
              ? '${AppConfig.serverHost}${e['logoUrl']}'
              : (e['logoUrl']?.toString() ?? ''),
          status: e['status'] ?? 'Sedang Direview',
          dilamarPada: e['dilamarPada'] ?? '',
        )).toList();
        
        state = state.copyWith(
          items: loadMore ? [...state.items, ...items] : items,
          isLoading: false,
          isLoadingMore: false,
          hasMore: items.length >= _limit,
        );
      } else {
        state = state.copyWith(
          isLoading: false, 
          isLoadingMore: false,
          error: 'Gagal mengambil data'
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        isLoadingMore: false,
        error: e.toString()
      );
    }
  }
}

final lamaranProvider =
    StateNotifierProvider.autoDispose<LamaranController, LamaranState>(
  (ref) => LamaranController(ref),
);
