import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ika_jtk_portal/shared/utils/file_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/format_utils.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/utils/country_codes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import 'widgets/member_app_bar.dart';
import 'widgets/verification_status_banner.dart';
import 'widgets/profile_section.dart';

const double _kAvatarColumnWidth = 216;
const double _kAvatarWidth = 200;
const double _kAvatarHeight = 240;
const double _kMobileAvatarWidth = 160;
const double _kMobileAvatarHeight = 192;
const double _kTwoColumnBreakpoint = 640;
const double _kSectionGap = 32;

class MyProfilePage extends ConsumerWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const MemberAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 32,
            maxContentWidth: 1100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROFILE SAYA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.nama ?? '-',
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 40, height: 3, color: AppColors.accent),
                if (user?.motto != null && user!.motto!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '"${user.motto}"',
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (user != null) ...[
                  const SizedBox(height: 20),
                  VerificationStatusBanner(
                    status: user.status,
                    rejectionReason: user.rejectionReason,
                  ),
                  _AlumniGrafisRejectedBanner(alumniGrafis: user.alumniGrafis),
                ],
                const SizedBox(height: _kSectionGap),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.maxWidth >= _kTwoColumnBreakpoint;
                    final avatarBlock = _AvatarBlock(
                      user: user,
                      width: isWide ? _kAvatarWidth : _kMobileAvatarWidth,
                      height: isWide ? _kAvatarHeight : _kMobileAvatarHeight,
                    );
                    final sections = _ProfileSections(user: user);
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: _kAvatarColumnWidth,
                            child: avatarBlock,
                          ),
                          const SizedBox(width: 48),
                          Expanded(child: sections),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        avatarBlock,
                        const SizedBox(height: _kSectionGap),
                        sections,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  final AlumniProfile? user;
  final double width;
  final double height;
  const _AvatarBlock({
    required this.user,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarUrl ?? '';
    final showImage = avatarUrl.isNotEmpty;
    final finalUrl = resolveThumbnailUrl(avatarUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: width,
            height: height,
            child: showImage
                ? Image.network(
                    finalUrl,
                    key: ValueKey(finalUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _InitialsBox(name: user?.nama ?? '', size: 48),
                  )
                : _InitialsBox(name: user?.nama ?? '', size: 48),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: width,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/member/profile/edit'),
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Edit Profile'),
          ),
        ),
      ],
    );
  }
}

String _formatPhone62(String? raw) {
  if (raw == null) return '-';
  var hp = raw.trim().replaceAll(RegExp(r'\D'), '');
  if (hp.isEmpty) return '-';

  final sortedCodes = List<Map<String, String>>.from(countryCodes)
    ..sort((a, b) => b['code']!.length.compareTo(a['code']!.length));

  Map<String, String>? matchedCode;
  for (var c in sortedCodes) {
    if (hp.startsWith(c['code']!)) {
      matchedCode = c;
      break;
    }
  }

  var formatted = '';
  if (matchedCode != null) {
    final code = matchedCode['code']!;
    hp = hp.substring(code.length);
    formatted = '+$code ';

    if (hp.length > 3) {
      formatted += '${hp.substring(0, 3)} ';
      hp = hp.substring(3);
    }
    if (hp.length > 4) {
      formatted += '${hp.substring(0, 4)} ';
      hp = hp.substring(4);
    }
    formatted += hp;
  } else {
    if (hp.startsWith('62')) hp = hp.substring(2);
    else if (hp.startsWith('0')) hp = hp.substring(1);
    formatted = '+62 ';
    if (hp.length > 3) {
      formatted += '${hp.substring(0, 3)} ';
      hp = hp.substring(3);
    }
    if (hp.length > 4) {
      formatted += '${hp.substring(0, 4)} ';
      hp = hp.substring(4);
    }
    formatted += hp;
  }
  return formatted.trim();
}

class _LinkedInLink extends StatelessWidget {
  final String url;
  const _LinkedInLink({required this.url});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        var urlStr = url;
        if (!urlStr.startsWith('http')) urlStr = 'https://$urlStr';
        final uri = Uri.parse(urlStr);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Text(
        url,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _ProfileSections extends StatelessWidget {
  final AlumniProfile? user;
  const _ProfileSections({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSection(
          title: 'Data Alumni',
          child: Column(
            children: [
              ProfileDataRow(
                label: 'No. Alumni',
                value: user?.noAlumni != null ? '#${user!.noAlumni}' : '-',
              ),
              ProfileDataRow(
                label: 'Angkatan',
                value: user?.angkatan?.toString() ?? '-',
              ),
              ProfileDataRow(
                label: 'Keanggotaan',
                valueWidget: _MembershipChip(
                  label: user?.keanggotaan ?? 'Alumni',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _kSectionGap),
        ProfileSection(
          title: 'Kontak',
          child: Column(
            children: [
              ProfileDataRow(label: 'Email', value: user?.email ?? '-'),
              ProfileDataRow(
                label: 'Nomor Handphone',
                value: _formatPhone62(user?.hp),
              ),
              ProfileDataRow(
                label: 'LinkedIn',
                valueWidget: (() {
                  final url = user?.linkedin;
                  if (url == null || url.isEmpty) return null;
                  return _LinkedInLink(url: url);
                })(),
                value: user?.linkedin ?? '-',
              ),
              ProfileDataRow(label: 'Alamat', value: user?.alamat ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: _kSectionGap),
        ProfileSection(
          title: 'Ijazah / PDDIKTI / Surat Keterangan Jurusan',
          child: Column(
            children: [
              ProfileDataRow(
                label: 'Nomor Ijazah / PDDIKTI / Surat Keterangan Jurusan',
                value: user?.nomorIjazah ?? '-',
              ),
              ProfileDataRow(
                label: 'Tahun Lulus',
                value: user?.tahunLulus?.toString() ?? '-',
              ),
              ProfileDataRow(
                label: 'IPK',
                value: user?.ipk?.toString() ?? '-',
              ),
              ProfileDataRow(
                label: 'File Ijazah / PDDIKTI / Surat Keterangan Jurusan',
                valueWidget:
                    user?.ijazahFile != null && user!.ijazahFile!.isNotEmpty
                    ? Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: InkWell(
                              onTap: () {},
                              child: Text(
                                formatFileName(user!.ijazahFile),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        '-',
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontSize: 13,
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _kSectionGap),
        ProfileSection(
          title: 'Pekerjaan',
          child: _PekerjaanList(items: user?.pekerjaan ?? const []),
        ),
        const SizedBox(height: _kSectionGap),
        ProfileSection(
          title: 'Prestasi',
          child: _PrestasiList(items: user?.prestasi ?? const []),
        ),
      ],
    );
  }
}

class _PekerjaanList extends StatelessWidget {
  final List<dynamic> items;
  const _PekerjaanList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'Belum ada data pekerjaan',
        style: TextStyle(color: AppColors.gray500, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((raw) {
        final p = raw as Map<String, dynamic>;
        final start = _joinMonthYear(p['bulanMulai'], p['tahunMulai']);
        final end = p['masihBekerja'] == true
            ? 'Present'
            : _joinMonthYear(p['bulanSelesai'], p['tahunSelesai']);
        final period = [start, end].where((s) => s.isNotEmpty).join(' - ');
        return ProfileTimelineRow(
          title: (p['pekerjaan'] ?? '').toString(),
          subtitle: (p['perusahaan'] ?? '').toString(),
          trailing: period,
        );
      }).toList(),
    );
  }

  String _joinMonthYear(dynamic month, dynamic year) {
    final m = (month ?? '').toString().trim();
    final y = (year ?? '').toString().trim();
    if (m.isEmpty && y.isEmpty) return '';
    if (m.isEmpty) return y;
    if (y.isEmpty) return m;
    return '$m $y';
  }
}

class _PrestasiList extends StatelessWidget {
  final List<dynamic> items;
  const _PrestasiList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'Belum ada data prestasi',
        style: TextStyle(color: AppColors.gray500, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final idx = entry.key;
        final p = entry.value as Map<String, dynamic>;
        final buktiUrl = p['buktiUrl']?.toString();
        return Padding(
          padding: EdgeInsets.only(bottom: idx == items.length - 1 ? 0 : 12),
          child: _AchievementRow(
            title: (p['judul'] ?? '').toString(),
            year: (p['tahun'] ?? '').toString(),
            buktiUrl: buktiUrl,
          ),
        );
      }).toList(),
    );
  }
}

class _MembershipChip extends StatelessWidget {
  final String label;
  const _MembershipChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isAlumni = label.toLowerCase() == 'alumni';
    final chipColor = isAlumni ? AppColors.gray500 : AppColors.accent;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final String title;
  final String year;
  final String? buktiUrl;
  const _AchievementRow({required this.title, required this.year, this.buktiUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              year,
              style: const TextStyle(color: AppColors.gray500, fontSize: 12),
            ),
          ],
        ),
        if (buktiUrl != null && buktiUrl!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                buktiUrl!.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final urlStr = buktiUrl!;
                    final url = Uri.parse(urlStr.startsWith('/') ? '${AuthController.serverHost}$urlStr' : urlStr);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Text(
                    formatFileName(buktiUrl),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]
      ],
    );
  }
}

class _InitialsBox extends StatelessWidget {
  final String name;
  final double size;
  const _InitialsBox({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: size,
        ),
      ),
    );
  }
}

class _AlumniGrafisRejectedBanner extends StatelessWidget {
  final dynamic alumniGrafis;
  const _AlumniGrafisRejectedBanner({required this.alumniGrafis});

  @override
  Widget build(BuildContext context) {
    // Decode alumniGrafis — bisa berupa Map atau JSON string
    Map<String, dynamic>? grafis;
    try {
      if (alumniGrafis is Map) {
        grafis = Map<String, dynamic>.from(alumniGrafis as Map);
      } else if (alumniGrafis is String && (alumniGrafis as String).isNotEmpty) {
        grafis = jsonDecode(alumniGrafis as String) as Map<String, dynamic>?;
      }
    } catch (_) {}

    final status = grafis?['status']?.toString().toUpperCase() ?? '';
    if (status != 'REJECTED') return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFF991B1B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengajuan Alumni Grafis Ditolak',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'data belum sesuai dengan syarat dan ketentuan yang berlaku',
                  style: TextStyle(
                    color: const Color(0xFF991B1B).withValues(alpha: 0.9),
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
}
