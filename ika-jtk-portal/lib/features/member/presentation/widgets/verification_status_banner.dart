import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';
import '../../../../core/enums/alumni_status.dart';

/// Banner yang menampilkan status verifikasi akun alumni kepada user.
///
/// - PENDING/UNVERIFIED : menunggu verifikasi admin (info).
/// - REJECTED           : akun ditolak admin (danger) — inilah keterangan
///                        yang sebelumnya tidak muncul di sisi user.
/// - INACTIVE           : akun dinonaktifkan.
/// - APPROVED/ACTIVE    : tidak menampilkan apa-apa (SizedBox kosong).
class VerificationStatusBanner extends StatelessWidget {
  final AlumniStatus status;
  final String? rejectionReason;

  const VerificationStatusBanner({
    super.key,
    required this.status,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    final _BannerStyle? style = _styleFor(status);
    if (style == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: style.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.foreground, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.title,
                  style: TextStyle(
                    color: style.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  style.message,
                  style: TextStyle(
                    color: style.foreground.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _BannerStyle? _styleFor(AlumniStatus status) {
    switch (status) {
      case AlumniStatus.rejected:
        final reasonText = (rejectionReason != null && rejectionReason!.trim().isNotEmpty)
            ? rejectionReason!.trim()
            : 'data belum sesuai dengan syarat dan ketentuan yang berlaku';
        return _BannerStyle(
          title: 'Akun Ditolak',
          message:
              'Verifikasi akun Anda ditolak oleh admin karena '
              'data belum sesuai dengan syarat dan ketentuan yang berlaku. '
              '\n\nAlasan ditolak : $reasonText\n\n'
              'Silakan perbaiki data profil Anda (pastikan semua data wajib terisi), '
              'lalu tekan Simpan untuk mengajukan verifikasi ulang secara otomatis.',
          icon: Icons.cancel_outlined,
          foreground: const Color(0xFF991B1B),
          background: const Color(0xFFFEE2E2),
          border: const Color(0xFFFCA5A5),
        );
      case AlumniStatus.pending:
      case AlumniStatus.unverified:
        return const _BannerStyle(
          title: 'Menunggu Verifikasi',
          message:
              'Akun Anda sedang menunggu verifikasi dari admin.\n'
              'Anda akan menerima notifikasi setelah proses selesai.',
          icon: Icons.hourglass_top_outlined,
          foreground: Color(0xFF92400E),
          background: Color(0xFFFEF3C7),
          border: Color(0xFFFCD34D),
        );
      case AlumniStatus.inactive:
        return const _BannerStyle(
          title: 'Akun Nonaktif',
          message:
              'Akun Anda saat ini nonaktif. Silakan hubungi pengurus IKA JTK '
              'untuk mengaktifkan kembali.',
          icon: Icons.block_outlined,
          foreground: Color(0xFF991B1B),
          background: Color(0xFFFEE2E2),
          border: Color(0xFFFCA5A5),
        );
      case AlumniStatus.approved:
      case AlumniStatus.active:
        return null;
    }
  }
}

class _BannerStyle {
  final String title;
  final String message;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;

  const _BannerStyle({
    required this.title,
    required this.message,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });
}
