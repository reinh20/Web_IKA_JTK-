import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ika_jtk_portal/core/app_config.dart';
import 'package:ika_jtk_portal/core/error_handler.dart';
import 'package:ika_jtk_portal/core/enums/alumni_status.dart';

class AlumniProfile {
  final String id;
  final String? noAlumni;
  final String nama;
  final String email;
  final String username;
  final int? angkatan;
  final String tanggalLahir;
  final String jenisKelamin;
  final AlumniStatus status;
  final String avatarUrl;
  final String? motto;
  final String? hp;
  final String? linkedin;
  final String? alamat;
  final String? nomorIjazah;
  final int? tahunLulus;
  final double? ipk;
  final String? ijazahFile;
  final List<dynamic> pekerjaan;
  final List<dynamic> prestasi;
  final String keanggotaan;
  final String emailVisibility;
  final String hpVisibility;
  final String alamatVisibility;
  final dynamic alumniGrafis;
  final String? rejectionReason;

  const AlumniProfile({
    required this.id,
    this.noAlumni,
    required this.nama,
    required this.email,
    required this.username,
    required this.angkatan,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.status,
    required this.avatarUrl,
    this.motto,
    this.hp,
    this.linkedin,
    this.alamat,
    this.nomorIjazah,
    this.tahunLulus,
    this.ipk,
    this.ijazahFile,
    this.pekerjaan = const [],
    this.prestasi = const [],
    this.keanggotaan = 'Alumni',
    this.emailVisibility = 'private',
    this.hpVisibility = 'private',
    this.alamatVisibility = 'private',
    this.alumniGrafis,
    this.rejectionReason,
  });

  static String get _backendBase => AppConfig.serverHost;

  static String _normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return '$_backendBase$url';
    return '$_backendBase/$url';
  }

  factory AlumniProfile.fromJson(Map<String, dynamic> json) {
    return AlumniProfile(
      id: json['id'].toString(),
      noAlumni: json['noAlumni']?.toString(),
      nama: json['nama']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      angkatan: json['angkatan'] != null ? int.tryParse(json['angkatan'].toString()) : null,
      tanggalLahir: json['tanggalLahir']?.toString() ?? '',
      jenisKelamin: json['jenisKelamin']?.toString() ?? '',
      status: AlumniStatus.fromString(json['status']?.toString() ?? ''),
      avatarUrl: _normalizeUrl(json['avatarUrl']?.toString()),
      motto: json['motto']?.toString(),
      hp: json['hp']?.toString(),
      linkedin: json['linkedin']?.toString(),
      alamat: json['alamat']?.toString(),
      nomorIjazah: json['nomorIjazah']?.toString(),
      tahunLulus: json['tahunLulus'] != null ? int.tryParse(json['tahunLulus'].toString()) : null,
      ipk: json['ipk'] != null 
          ? (json['ipk'] is num ? (json['ipk'] as num).toDouble() : double.tryParse(json['ipk'].toString())) 
          : null,
      ijazahFile: _normalizeUrl(json['ijazahFile']?.toString()),
      pekerjaan: json['pekerjaan'] as List<dynamic>? ?? const [],
      prestasi: json['prestasi'] as List<dynamic>? ?? const [],
      keanggotaan: json['keanggotaan']?.toString() ?? 'Alumni',
      emailVisibility: json['emailVisibility']?.toString() ?? 'private',
      hpVisibility: json['nomorHandphoneVisibility']?.toString() ?? 'private',
      alamatVisibility: json['alamatVisibility']?.toString() ?? 'private',
      alumniGrafis: json['alumniGrafis'],
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'noAlumni': noAlumni,
      'nama': nama,
      'email': email,
      'username': username,
      'angkatan': angkatan,
      'tanggalLahir': tanggalLahir,
      'jenisKelamin': jenisKelamin,
      'status': status.value,
      'avatarUrl': avatarUrl,
      'motto': motto,
      'hp': hp,
      'linkedin': linkedin,
      'alamat': alamat,
      'nomorIjazah': nomorIjazah,
      'tahunLulus': tahunLulus,
      'ipk': ipk,
      'ijazahFile': ijazahFile,
      'pekerjaan': pekerjaan,
      'prestasi': prestasi,
      'keanggotaan': keanggotaan,
      'emailVisibility': emailVisibility,
      'nomorHandphoneVisibility': hpVisibility,
      'alamatVisibility': alamatVisibility,
      'alumniGrafis': alumniGrafis,
      'rejectionReason': rejectionReason,
    };
  }

  static const fulan = AlumniProfile(
    id: 'mock-1',
    nama: 'Fulan',
    email: 'fulan@ikajtk.id',
    username: 'fulan',
    avatarUrl: 'https://i.pravatar.cc/150?u=fulan-member',
    angkatan: 2018,
    tanggalLahir: '01/01/1996',
    jenisKelamin: 'Laki-laki',
    status: AlumniStatus.active,
    keanggotaan: 'Alumni',
  );
}

class AuthState {
  final AlumniProfile? user;
  final String? token;
  /// True setelah _loadSession() selesai dijalankan pertama kali.
  /// Router harus menunggu flag ini true sebelum membuat keputusan redirect.
  final bool isInitialized;
  final bool isLoading;
  final bool sessionExpired;

  const AuthState({
    this.user,
    this.token,
    this.isInitialized = false,
    this.isLoading = false,
    this.sessionExpired = false,
  });

  bool get isLoggedIn => user != null && token != null;

  AuthState copyWith({
    AlumniProfile? user,
    String? token,
    bool? isInitialized,
    bool? isLoading,
    bool? sessionExpired,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) {
    _loadSession();
  }

  static String get serverHost => AppConfig.serverHost;
  static String get baseUrl => '$serverHost/api/auth';

  static dynamic _decodeResponse(http.Response res, {String defaultMessage = 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.'}) {
    if (res.body.isEmpty || !res.body.trim().startsWith('{')) {
      ErrorHandler.logSystemError('Non-JSON HTTP response (${res.statusCode}): ${res.body}', context: 'auth_provider._decodeResponse');
      throw Exception(defaultMessage);
    }
    try {
      return jsonDecode(res.body);
    } catch (e, st) {
      ErrorHandler.logSystemError('Failed to parse JSON response: $e | Body: ${res.body}', stackTrace: st, context: 'auth_provider._decodeResponse');
      throw Exception(defaultMessage);
    }
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userStr = prefs.getString('auth_user');

      if (token != null && userStr != null) {
        final userMap = jsonDecode(userStr);
        final user = AlumniProfile.fromJson(userMap);
        // Langsung set user dari cache, tandai sudah ter-inisialisasi
        state = AuthState(user: user, token: token, isLoading: false, isInitialized: true);

        // Fetch fresh profile dari API di background (tidak blokir UI)
        if (token != 'mock-token') {
          _refreshProfileFromApi(token);
        }
      } else {
        // Tidak ada session tersimpan — tandai sudah ter-inisialisasi tanpa user
        state = const AuthState(isInitialized: true);
      }
    } catch (e) {
      // Jika ada error membaca storage, anggap tidak login
      state = const AuthState(isInitialized: true);
    }
  }

  Future<void> _refreshProfileFromApi(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final freshUser = AlumniProfile.fromJson(data['user']);
        state = state.copyWith(user: freshUser);
        await _saveSession(freshUser, token);
      } else if (res.statusCode == 401) {
        // Token expired atau tidak valid — tampilkan modal expired
        state = state.copyWith(sessionExpired: true);
      }
    } catch (_) {
      // Gagal fetch API — cached data tetap ditampilkan, tidak logout
    }
  }

  Future<void> _saveSession(AlumniProfile user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_user', jsonEncode(user.toJson()));
    } catch (e) {
      // ignore
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    } catch (e) {
      // ignore
    }
  }

  Future<void> login(String emailOrUsername, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrUsername': emailOrUsername,
          'password': password,
        }),
      );

      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        final user = AlumniProfile.fromJson(data['user']);
        final token = data['token'] as String;
        state = AuthState(user: user, token: token, isLoading: false, isInitialized: true);
        await _saveSession(user, token);
      } else {
        final data = _decodeResponse(res, defaultMessage: 'Gagal masuk');
        if (data['needsVerification'] == true) {
          throw Exception('VERIFICATION_NEEDED:${data['email']}');
        }
        throw Exception(data['message'] ?? 'Gagal masuk');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> register({
    required String nama,
    required String angkatan,
    required String tanggalLahir,
    required String jenisKelamin,
    required String email,
    required String username,
    required String password,
    required bool userAgreement,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'angkatan': angkatan,
          'tanggalLahir': tanggalLahir,
          'jenisKelamin': jenisKelamin,
          'email': email,
          'username': username,
          'password': password,
          'userAgreement': userAgreement,
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Permintaan melebihi batas waktu. Silakan coba lagi.'),
      );

      if (res.statusCode == 201) {
        state = state.copyWith(isLoading: false);
      } else {
        final data = _decodeResponse(res, defaultMessage: 'Gagal mendaftar');
        throw Exception(data['message'] ?? 'Gagal mendaftar');
      }
    } on Exception catch (e) {
      ErrorHandler.logSystemError(e, context: 'auth_provider.register');
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<bool> checkUnique({String? email, String? username}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/check-unique'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (email != null) 'email': email,
          if (username != null) 'username': username,
        }),
      );
      if (res.statusCode == 200) {
        return true;
      } else {
        final data = _decodeResponse(res, defaultMessage: 'Email atau Username sudah digunakan');
        throw Exception(data['message'] ?? 'Email atau Username sudah digunakan');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      if (res.statusCode == 200) {
        final data = _decodeResponse(res);
        final user = AlumniProfile.fromJson(data['user']);
        final token = data['token'] as String;
        state = AuthState(user: user, token: token, isLoading: false, isInitialized: true);
        await _saveSession(user, token);
      } else {
        final data = _decodeResponse(res, defaultMessage: 'Gagal memverifikasi email');
        throw Exception(data['message'] ?? 'Gagal memverifikasi email');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> resendOtp(String email) async {
    state = state.copyWith(isLoading: true);
    try {


      final uri = Uri.parse('$baseUrl/resend-otp');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      state = state.copyWith(isLoading: false);

      if (response.statusCode != 200) {
        final data = _decodeResponse(response, defaultMessage: 'Gagal mengirim ulang kode OTP');
        throw Exception(data['message'] ?? 'Gagal mengirim ulang kode OTP');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    state = state.copyWith(isLoading: true);
    try {
      if (state.token == null) {
        throw Exception('Not authenticated');
      }

      final res = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${state.token}',
        },
        body: jsonEncode(profileData),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final updatedUser = AlumniProfile.fromJson(data['user']);

        // Evict old avatar from cache if URL changed
        final oldUrl = state.user?.avatarUrl ?? '';
        if (oldUrl.isNotEmpty && oldUrl != updatedUser.avatarUrl) {
          final cacheUrl = oldUrl.startsWith('/')
              ? '$serverHost$oldUrl'
              : oldUrl;
          await CachedNetworkImage.evictFromCache(cacheUrl);
        }

        state = state.copyWith(user: updatedUser, isLoading: false);
        if (state.token != null) {
          await _saveSession(updatedUser, state.token!);
        }
      } else {
        String errorMessage = 'Terjadi kesalahan sistem. Silakan coba lagi nanti.';
        try {
          final data = jsonDecode(res.body);
          if (res.statusCode < 500 && data['message'] != null) {
            errorMessage = data['message'];
          }
        } catch (_) {
          // Keep generic error if JSON is invalid
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (e is FormatException) {
        throw Exception('Terjadi gangguan pada server. Silakan coba lagi nanti.');
      }
      rethrow;
    }
  }

  Future<String> uploadFile(List<int> fileBytes, String filename, {String type = 'avatar'}) async {
    state = state.copyWith(isLoading: true);
    try {
      if (state.token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('$serverHost/api/upload/$type');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${state.token}';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        fileBytes,
        filename: filename,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      state = state.copyWith(isLoading: false);

      if (response.statusCode == 200) {
        final data = _decodeResponse(response);
        return data['url'] as String;
      } else {
        final data = _decodeResponse(response, defaultMessage: 'Gagal mengunggah file');
        throw Exception(data['error'] ?? data['message'] ?? 'Gagal mengunggah file');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      state = state.copyWith(isLoading: false);
      if (res.statusCode != 200) {
        final data = _decodeResponse(res, defaultMessage: 'Gagal mengirim permintaan reset kata sandi');
        throw Exception(data['message'] ?? 'Gagal mengirim permintaan reset kata sandi');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      state = state.copyWith(isLoading: false);
      if (res.statusCode != 200) {
        final data = _decodeResponse(res, defaultMessage: 'Gagal mereset kata sandi');
        throw Exception(data['message'] ?? 'Gagal mereset kata sandi');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/logout');
        await http.post(uri, headers: {'Authorization': 'Bearer $token'});
      }
    } catch (_) {}
    state = const AuthState(isInitialized: true);
    _clearSession();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
