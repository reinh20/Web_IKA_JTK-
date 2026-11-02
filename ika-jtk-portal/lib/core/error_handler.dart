import 'dart:developer' as developer;

class ErrorHandler {
  /// Riwayat log error sistem untuk inspeksi debug atau pengiriman ke analytics.
  static final List<Map<String, dynamic>> systemErrorLogs = [];

  /// Mencatat error sistem secara terstruktur ke memori dan terminal console.
  static void logSystemError(dynamic error, {StackTrace? stackTrace, String? context}) {
    if (error == null) return;
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = {
      'timestamp': timestamp,
      'error': error.toString(),
      'context': context ?? 'general',
      'stackTrace': stackTrace?.toString(),
    };
    systemErrorLogs.add(logEntry);
    if (systemErrorLogs.length > 200) {
      systemErrorLogs.removeAt(0);
    }
    print('[SYSTEM_ERROR_LOG] [$timestamp] [${context ?? 'GENERAL'}] $error');
    if (stackTrace != null) {
      print('[SYSTEM_ERROR_TRACE] $stackTrace');
    }
    developer.log('[SYSTEM_ERROR_LOG] [$timestamp]', error: error, stackTrace: stackTrace);
  }

  /// Memproses error yang ditangkap (dari try-catch), mencetaknya ke terminal,
  /// dan mengembalikan pesan yang aman untuk pengguna (tidak teknis).
  /// 
  /// [defaultMessage] adalah pesan standar yang akan ditampilkan jika pesan dari
  /// error terlalu teknis atau tidak dikenali.
  static String getFriendlyMessage(dynamic error, {String defaultMessage = 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.'}) {
    // 1. Log error ke terminal dan catat ke riwayat log error sistem
    logSystemError(error, context: 'getFriendlyMessage');

    if (error == null) return defaultMessage;

    final errorString = error.toString();

    // 2. Daftar kata kunci teknis yang mengindikasikan pesan ini tidak boleh
    //    ditampilkan ke layar pengguna.
    final technicalKeywords = [
      'dioexception',
      'socketexception',
      'sqlexception',
      'pdoexception',
      'format exception',
      'formatexception',
      'formatsyntaxerror',
      'syntaxerror',
      'unexpected end of json input',
      'unexpected token',
      'typeerror',
      'connection refused',
      'timeout',
      'null check',
      'xmlhttprequest error',
      'xmlhttprequest',
      'clientexception',
      'httpexception',
      'networkerror',
      'failed to fetch',
      'bad gateway',
      'gateway timeout',
      'internal server error',
      'json',
      'html',
      'http://',
      'https://',
      'status code',
      'error 500',
      'error 502',
      'error 503',
      'error 504',
      'error 400',
      'error 404',
      'error 401',
      'error 403',
      'uncaught',
      'stack trace',
      'syntax error',
    ];

    final lowerError = errorString.toLowerCase();
    
    // Cek apakah pesan error mengandung istilah teknis
    for (var keyword in technicalKeywords) {
      if (lowerError.contains(keyword)) {
        // Jika iya, dan kita tahu ini masalah koneksi:
        if (keyword == 'socketexception' || keyword == 'connection refused' || keyword == 'timeout') {
          return 'Gagal terhubung ke server. Harap periksa koneksi internet Anda.';
        }
        // Jika tidak, gunakan pesan fallback yang aman
        return defaultMessage;
      }
    }

    // 3. Bersihkan prefix 'Exception: ' yang sering muncul jika backend melempar exception manual
    String cleanMessage = errorString.replaceAll('Exception: ', '').trim();

    // 4. Pastikan pesan tidak mengandung istilah teknis bahasa Inggris yang tersisa
    final englishErrorWords = [
      'error',
      'exception',
      'syntax',
      'unexpected',
      'invalid json',
      'failed',
      'null',
      'undefined',
      'uncaught',
      'stack',
    ];
    final lowerClean = cleanMessage.toLowerCase();
    for (var word in englishErrorWords) {
      if (lowerClean.contains(word)) {
        return defaultMessage;
      }
    }

    // Jika pesan yang tersisa pendek dan tidak teknis, kemungkinan itu adalah 
    // pesan valid dari server (misal: "Username sudah digunakan")
    if (cleanMessage.length < 100) {
      // Pengecualian khusus jika ingin menangani pesan dari provider
      return cleanMessage;
    }

    // Jika terlalu panjang atau tidak dikenali, gunakan pesan default
    return defaultMessage;
  }
}
