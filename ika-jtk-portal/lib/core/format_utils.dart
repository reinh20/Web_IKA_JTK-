import 'app_config.dart';

const _monthsFull = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Turns a stored image path into a fully-qualified URL.
///
/// - Relative paths (`/uploads/x.png`) are prefixed with the backend host.
/// - Absolute URLs (`http...`) are returned as-is.
/// - Empty / null input returns an empty string so callers can show a
///   placeholder instead of a broken image request.
String resolveImageUrl(String? raw, {String? fallbackName}) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) {
    if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      final encodedName = Uri.encodeComponent(fallbackName.trim());
      return 'https://ui-avatars.com/api/?name=$encodedName&background=random&format=png';
    }
    return '';
  }
  if (value.startsWith('http://') || value.startsWith('https://') || value.startsWith('data:') || value.startsWith('assets/')) {
    return value;
  }
  final host = AppConfig.serverHost.replaceAll(RegExp(r'/$'), '');
  final path = value.startsWith('/') ? value : '/$value';
  return '$host$path';
}

/// Tries to resolve a thumbnail URL by appending `_thumb` before the extension.
String resolveThumbnailUrl(String? raw, {String? fallbackName}) {
  final url = resolveImageUrl(raw, fallbackName: fallbackName);
  if (url.isEmpty || url.startsWith('data:') || url.contains('ui-avatars.com')) return url;
  
  final lastDot = url.lastIndexOf('.');
  if (lastDot != -1 && url.length - lastDot <= 5) {
    final withoutExt = url.substring(0, lastDot);
    if (!withoutExt.endsWith('_thumb')) {
      return '${withoutExt}_thumb${url.substring(lastDot)}';
    }
  }
  return url;
}

/// Formats an ISO date string into `d MMMM yyyy` (e.g. `1 Juli 2026`).
/// Falls back to the original string when it can't be parsed.
String formatTanggal(String? iso, {bool short = false}) {
  final value = (iso ?? '').trim();
  if (value.isEmpty) return '';
  final dt = DateTime.tryParse(value);
  if (dt == null) return value;
  final local = dt.toLocal();
  final months = short ? _monthsShort : _monthsFull;
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

/// Formats an ISO date string into `d MMMM yyyy, HH:mm WIB` (e.g. `1 Juli 2026, 14:30 WIB`).
String formatTanggalWaktu(String? iso, {bool short = false}) {
  final value = (iso ?? '').trim();
  if (value.isEmpty) return '';
  final dt = DateTime.tryParse(value);
  if (dt == null) return value;
  final local = dt.toLocal();
  final months = short ? _monthsShort : _monthsFull;
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} ${local.year}, $hh:$mm WIB';
}

/// Returns a human-friendly Indonesian relative time string
/// (e.g. `5 menit yang lalu`, `2 hari yang lalu`).
/// Returns empty string when input can't be parsed.
String formatRelativeTime(String? iso) {
  final value = (iso ?? '').trim();
  if (value.isEmpty) return '';
  final dt = DateTime.tryParse(value);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inSeconds < 60) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu yang lalu';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan yang lalu';
  return '${(diff.inDays / 365).floor()} tahun yang lalu';
}

/// Extracts the time portion (`HH:mm`) from an ISO datetime string.
/// Returns an empty string when there is no time component.
String formatWaktu(String? iso) {
  final value = (iso ?? '').trim();
  if (value.isEmpty) return '';
  final dt = DateTime.tryParse(value);
  if (dt == null) return '';
  final local = dt.toLocal();
  // A date-only value (midnight) usually means no specific time was set.
  if (local.hour == 0 && local.minute == 0 && local.second == 0) return '';
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm WIB';
}
