import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_config.dart';

class Testimoni {
  final String id;
  final String alumniNama;
  final String alumniAngkatan;
  final String alumniAvatarUrl;
  final String isi;
  final String status;
  final String createdAt;
  final String? rejectReason;

  const Testimoni({
    required this.id,
    required this.alumniNama,
    required this.alumniAngkatan,
    required this.alumniAvatarUrl,
    required this.isi,
    required this.status,
    required this.createdAt,
    this.rejectReason,
  });

  factory Testimoni.fromJson(Map<String, dynamic> json) {
    return Testimoni(
      id: json['id']?.toString() ?? '',
      alumniNama: json['alumniNama']?.toString() ?? '',
      alumniAngkatan: json['alumniAngkatan']?.toString() ?? '',
      alumniAvatarUrl: (json['alumniAvatarUrl']?.toString() ?? '').startsWith('/')
          ? '${AppConfig.serverHost}${json['alumniAvatarUrl']}'
          : (json['alumniAvatarUrl']?.toString() ?? ''),
      isi: json['isi']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt:
          (json['createdAt'] ?? json['submittedAt'])?.toString() ?? '',
      rejectReason: json['rejectReason']?.toString(),
    );
  }
}

class MyTestimoniInfo {
  final String id;
  final String isi;
  final String status;
  final String createdAt;
  final String? rejectReason;
  final int? rejectCount;

  const MyTestimoniInfo({
    required this.id,
    required this.isi,
    required this.status,
    required this.createdAt,
    this.rejectReason,
    this.rejectCount,
  });

  factory MyTestimoniInfo.fromJson(Map<String, dynamic> json) {
    return MyTestimoniInfo(
      id: json['id']?.toString() ?? '',
      isi: json['isi']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      rejectReason: json['rejectReason']?.toString(),
      rejectCount: json['rejectCount'] != null ? int.tryParse(json['rejectCount'].toString()) : 0,
    );
  }
}

class TestimoniState {
  final List<Testimoni> publicList;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final MyTestimoniInfo? myLatest;
  final bool myLatestLoading;
  final bool hasUnreadRejection;

  const TestimoniState({
    this.publicList = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.myLatest,
    this.myLatestLoading = false,
    this.hasUnreadRejection = false,
  });

  TestimoniState copyWith({
    List<Testimoni>? publicList,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    MyTestimoniInfo? myLatest,
    bool clearMyLatest = false,
    bool? myLatestLoading,
    bool? hasUnreadRejection,
  }) {
    return TestimoniState(
      publicList: publicList ?? this.publicList,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      myLatest: clearMyLatest ? null : (myLatest ?? this.myLatest),
      myLatestLoading: myLatestLoading ?? this.myLatestLoading,
      hasUnreadRejection: hasUnreadRejection ?? this.hasUnreadRejection,
    );
  }
}

class TestimoniController extends StateNotifier<TestimoniState> {
  TestimoniController() : super(const TestimoniState());

  String get baseUrl => AppConfig.apiBaseUrl;

  Future<void> fetchPublic({String? token}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http.get(
        Uri.parse('$baseUrl/testimoni'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data as List)
            .map((e) => Testimoni.fromJson(e as Map<String, dynamic>))
            .toList();
        list.shuffle();
        final limitedList = list.take(5).toList();
        state = state.copyWith(publicList: limitedList, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Gagal memuat testimoni.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal terhubung ke server.',
      );
    }
  }

  /// Fetches the latest testimonial for the current alumni.
  Future<void> fetchMyTestimoni({required String token}) async {
    state = state.copyWith(myLatestLoading: true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/testimoni/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (data != null) {
          final info = MyTestimoniInfo.fromJson(data as Map<String, dynamic>);
          bool hasUnread = false;
          if (info.status.toLowerCase() == 'rejected') {
            final prefs = await SharedPreferences.getInstance();
            final key = 'testimoni_rejected_shown_${info.id}_${info.rejectCount}';
            final alreadyShown = prefs.getBool(key) ?? false;
            hasUnread = !alreadyShown;
          }
          state = state.copyWith(
            myLatest: info,
            myLatestLoading: false,
            hasUnreadRejection: hasUnread,
          );
        } else {
          state = state.copyWith(
            clearMyLatest: true,
            myLatestLoading: false,
            hasUnreadRejection: false,
          );
        }
      } else {
        state = state.copyWith(myLatestLoading: false);
      }
    } catch (e) {
      state = state.copyWith(myLatestLoading: false);
    }
  }

  /// Marks the rejection notification as read, hiding the badge immediately.
  void markRejectionAsRead() {
    state = state.copyWith(hasUnreadRejection: false);
  }

  /// Submits a testimoni. Returns an error message on failure, or null on success.
  Future<String?> submitTestimoni({
    required String isi,
    required String visibility,
    required String token,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/testimoni'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isi': isi, 'visibility': visibility}),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        state = state.copyWith(isSubmitting: false);
        return null;
      }

      String error = 'Gagal mengirim testimoni.';
      try {
        final data = jsonDecode(res.body);
        error = data['error']?.toString() ??
            data['message']?.toString() ??
            error;
      } catch (_) {}
      state = state.copyWith(isSubmitting: false, error: error);
      return error;
    } catch (e) {
      const error = 'Gagal terhubung ke server.';
      state = state.copyWith(isSubmitting: false, error: error);
      return error;
    }
  }
}

final testimoniProvider =
    StateNotifierProvider<TestimoniController, TestimoniState>(
  (ref) => TestimoniController(),
);
