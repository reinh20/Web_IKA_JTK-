import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/tokens.dart';
import '../../../core/portal_data.dart';
import '../../../core/seo_helper.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/portal_network_image.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../providers/alumni_provider.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import 'widgets/member_app_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../pemilu/providers/pemilu_provider.dart';
import '../../../shared/utils/country_codes.dart';
import '../../../shared/widgets/breadcrumb.dart';

class AlumniPublicProfilePage extends ConsumerStatefulWidget {
  final String alumniId;
  const AlumniPublicProfilePage({super.key, required this.alumniId});

  @override
  ConsumerState<AlumniPublicProfilePage> createState() => _AlumniPublicProfilePageState();
}

class _AlumniPublicProfilePageState extends ConsumerState<AlumniPublicProfilePage> {
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await ref.read(alumniProvider.notifier).getDetail(widget.alumniId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
    }
  }

  AlumniDirEntry _getFromList() {
    final list = ref.watch(alumniProvider).items;
    for (final a in list) {
      if (a.id == widget.alumniId) return a;
    }
    for (final a in PortalData.alumniDirectory) {
      if (a.id == widget.alumniId) return a;
    }
    final candidates = ref.watch(pemiluProvider).candidates;
    for (final c in candidates) {
      if (c.alumniId == widget.alumniId) {
        return AlumniDirEntry(
          id: c.alumniId ?? c.id,
          nama: c.nama,
          angkatan: c.angkatan,
          fotoUrl: c.fotoUrl,
          posisiSekarang: c.pengalaman.isNotEmpty ? c.pengalaman.first : (c.programKerja.isNotEmpty ? c.programKerja.first.title : 'Kandidat Pemilu IKA JTK'),
          perusahaan: 'Alumni IKA JTK',
        );
      }
    }
    for (final c in PortalData.candidates) {
      if (c.alumniId == widget.alumniId) {
        return AlumniDirEntry(
          id: c.alumniId ?? c.id,
          nama: c.nama,
          angkatan: c.angkatan,
          fotoUrl: c.fotoUrl,
          posisiSekarang: c.pengalaman.isNotEmpty ? c.pengalaman.first : (c.programKerja.isNotEmpty ? c.programKerja.first.title : 'Kandidat Pemilu IKA JTK'),
          perusahaan: 'Alumni IKA JTK',
        );
      }
    }
    return AlumniDirEntry(nama: 'Alumni', angkatan: null);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final isOwnProfile = loggedIn && ref.watch(authProvider).user?.id == widget.alumniId;
    final alumni = _detail != null
        ? AlumniDirEntry.fromJson(_detail!)
        : _getFromList();

    final candidate = ref.watch(pemiluProvider).candidates.where((c) => c.alumniId == widget.alumniId).firstOrNull ?? PortalData.candidates.where((c) => c.alumniId == widget.alumniId).firstOrNull;

    final pekerjaan = _detail != null
        ? (_detail!['pekerjaan'] as List<dynamic>? ?? [])
        : (candidate != null
            ? candidate.pengalaman.map((p) => {
                'pekerjaan': p,
                'perusahaan': 'Alumni IKA JTK',
                'tahunMulai': candidate.angkatan,
                'masihBekerja': true,
              }).toList()
            : <dynamic>[]);
    final prestasi = _detail != null
        ? (_detail!['prestasi'] as List<dynamic>? ?? [])
        : <dynamic>[];

    final appBar = loggedIn ? const MemberAppBar(activeKey: 'alumni') : const PublicAppBar(activeKey: 'alumni');

    if (alumni != null) {
      SeoHelper.update(
        title: 'Profil Alumni: ${alumni.nama}',
        description: 'Profil dan jejak karir ${alumni.nama} (Angkatan ${alumni.angkatan}) di IKA JTK POLBAN.',
        imageUrl: alumni.fotoUrl.isNotEmpty ? alumni.fotoUrl : (candidate?.fotoUrl ?? ''),
        type: 'profile',
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? StickyFooterScrollView(
              children: [
                appBar,
                const SizedBox(height: 120),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 120),
                const SiteFooter(),
              ],
            )
          : StickyFooterScrollView(
              children: [
                appBar,
                SectionWrapper(
                  verticalPadding: 32,
                  maxContentWidth: 1100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Breadcrumb(
                        items: [
                          BreadcrumbItem(
                            label: 'Beranda',
                            onTap: () => context.go(loggedIn ? '/member' : '/'),
                          ),
                          if (!loggedIn)
                            BreadcrumbItem(
                              label: 'Pemilu',
                              onTap: () => context.go('/pemilu'),
                            )
                          else
                            BreadcrumbItem(
                              label: 'Alumni',
                              onTap: () => context.go('/member/alumni'),
                            ),
                          BreadcrumbItem(label: !loggedIn ? 'Profil Alumni' : 'Profile'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        alumni.nama,
                        style: const TextStyle(
                          color: AppColors.gray900,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_detail != null && _detail!['motto'] != null && _detail!['motto'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${_detail!['motto'].toString()}"',
                          style: const TextStyle(
                            color: AppColors.gray600,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(width: 32, height: 2, color: AppColors.accent),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 240,
                            height: 280,
                            child: PortalNetworkImage(
                              url: alumni.fotoUrl.isNotEmpty ? alumni.fotoUrl : (candidate?.fotoUrl ?? ''),
                              fit: BoxFit.cover,
                              placeholderIcon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle('Data Alumni', showLine: true),
                                if (isOwnProfile && alumni.noAlumni != null)
                                  _DataRow(label: 'No. Alumni', value: '#${alumni.noAlumni}'),
                                _DataRow(label: 'Angkatan', value: alumni.angkatan?.toString()),
                                _DataRow(label: 'Keanggotaan', value: _detail?['keanggotaan']?.toString() ?? 'Alumni', isBadge: true),
                                const SizedBox(height: 32),
                                
                                _DataRow(label: 'Email', value: _detail?['email']?.toString() ?? '-'),
                                _DataRow(
                                  label: 'Nomor Handphone',
                                  value: (() {
                                    final hp = _detail?['nomorHandphone']?.toString();
                                    if (hp == null || hp.isEmpty) return '-';
                                    var hpRaw = hp.trim().replaceAll(RegExp(r'\D'), '');
                                    
                                    final sortedCodes = List<Map<String, String>>.from(countryCodes)
                                      ..sort((a, b) => b['code']!.length.compareTo(a['code']!.length));
                                    
                                    Map<String, String>? matchedCode;
                                    for (var c in sortedCodes) {
                                      if (hpRaw.startsWith(c['code']!)) {
                                        matchedCode = c;
                                        break;
                                      }
                                    }
                                    
                                    var formatted = '';
                                    if (matchedCode != null) {
                                      final code = matchedCode['code']!;
                                      hpRaw = hpRaw.substring(code.length);
                                      formatted = '+$code ';
                                      
                                      if (hpRaw.length > 3) {
                                        formatted += '${hpRaw.substring(0, 3)} ';
                                        hpRaw = hpRaw.substring(3);
                                      }
                                      if (hpRaw.length > 4) {
                                        formatted += '${hpRaw.substring(0, 4)} ';
                                        hpRaw = hpRaw.substring(4);
                                      }
                                      formatted += hpRaw;
                                    } else {
                                      if (hpRaw.startsWith('62')) hpRaw = hpRaw.substring(2);
                                      else if (hpRaw.startsWith('0')) hpRaw = hpRaw.substring(1);
                                      formatted = '+62 ';
                                      if (hpRaw.length > 3) {
                                        formatted += '${hpRaw.substring(0, 3)} ';
                                        hpRaw = hpRaw.substring(3);
                                      }
                                      if (hpRaw.length > 4) {
                                        formatted += '${hpRaw.substring(0, 4)} ';
                                        hpRaw = hpRaw.substring(4);
                                      }
                                      formatted += hpRaw;
                                    }
                                    return formatted.trim();
                                  })(),
                                ),
                                _DataRow(
                                  label: 'LinkedIn',
                                  valueWidget: (() {
                                    final linkedinStr = _detail?['linkedin']?.toString();
                                    if (linkedinStr == null || linkedinStr.trim().isEmpty) {
                                      return const Text('-', style: TextStyle(color: AppColors.gray900, fontSize: 13, fontWeight: FontWeight.w600));
                                    }
                                    return InkWell(
                                      onTap: () async {
                                        var urlStr = linkedinStr.trim();
                                        if (!urlStr.startsWith('http')) {
                                          urlStr = 'https://$urlStr';
                                        }
                                        final url = Uri.parse(urlStr);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      },
                                      child: Text(
                                        linkedinStr,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    );
                                  })(),
                                ),
                                _DataRow(label: 'Alamat', value: _detail?['alamat']?.toString() ?? '-'),
                                
                                if (pekerjaan.isNotEmpty) ...[
                                  const SizedBox(height: 32),
                                  _SectionTitle('Pekerjaan', showLine: true),
                                  Column(
                                    children: pekerjaan.map((p) {
                                      final job = p as Map<String, dynamic>;
                                      final masihBekerja = job['masihBekerja'] == true;
                                      
                                      String mStart = job['bulanMulai']?.toString() ?? '';
                                      if (mStart.length > 3) mStart = mStart.substring(0, 3);
                                      String mEnd = job['bulanSelesai']?.toString() ?? '';
                                      if (mEnd.length > 3) mEnd = mEnd.substring(0, 3);
                                      
                                      final tStart = job['tahunMulai']?.toString() ?? '';
                                      final tEnd = job['tahunSelesai']?.toString() ?? '';
                                      
                                      final start = mStart.isNotEmpty ? '$mStart $tStart' : tStart;
                                      final end = mEnd.isNotEmpty ? '$mEnd $tEnd' : tEnd;
                                      
                                      final period = masihBekerja
                                          ? '$start - Present'
                                          : '$start - $end';
                                          
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: pekerjaan.last == p ? 0 : 20,
                                        ),
                                        child: _Row(
                                          title: job['pekerjaan']?.toString() ?? '',
                                          subtitle: job['perusahaan']?.toString() ?? '',
                                          period: period,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                
                                if (prestasi.isNotEmpty) ...[
                                  const SizedBox(height: 32),
                                  _SectionTitle('Prestasi', showLine: true),
                                  Column(
                                    children: prestasi.map((p) {
                                      final item = p as Map<String, dynamic>;
                                      final tahun = item['tahun']?.toString() ?? '';
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: prestasi.last == p ? 0 : 20,
                                        ),
                                        child: _Row(
                                          title: item['judul']?.toString() ?? '',
                                          subtitle: '',
                                          period: tahun,
                                          action: (isOwnProfile && item['buktiUrl'] != null && item['buktiUrl'].toString().isNotEmpty)
                                              ? InkWell(
                                                  onTap: () async {
                                                    final urlStr = item['buktiUrl'].toString();
                                                    final url = Uri.parse(urlStr.startsWith('/') ? '${AuthController.serverHost}$urlStr' : urlStr);
                                                    if (await canLaunchUrl(url)) {
                                                      await launchUrl(url);
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Lihat Bukti',
                                                    style: TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 12,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool showLine;
  const _SectionTitle(this.title, {required this.showLine});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (showLine) ...[
          const SizedBox(height: 4),
          Container(width: 32, height: 2, color: AppColors.accent),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isBadge;

  const _DataRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.isBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (valueWidget == null && (value == null || value!.isEmpty || value == '-')) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.gray900,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: valueWidget ?? (isBadge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gray500,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        value ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    value ?? '',
                    style: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  )),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String subtitle;
  final String period;
  final Widget? action;
  const _Row({required this.title, required this.subtitle, required this.period, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (period.isNotEmpty)
          Text(
            period,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 12,
            ),
          ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ]
      ],
    );
  }
}

