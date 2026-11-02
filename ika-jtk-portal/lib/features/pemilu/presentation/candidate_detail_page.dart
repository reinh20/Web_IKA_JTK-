import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/html_content.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../providers/pemilu_provider.dart';
import '../../../core/portal_data.dart';
import '../../../core/seo_helper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import 'widgets/candidate_avatar.dart';

String _stripHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .trim();
}

class CandidateDetailPage extends ConsumerWidget {
  final String candidateId;
  const CandidateDetailPage({super.key, required this.candidateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final pemiluState = ref.watch(pemiluProvider);
    final hasVoted = pemiluState.hasVoted;
    final candidates = pemiluState.candidates;
    final isLoading = pemiluState.isLoading;

    if (isLoading && candidates.isEmpty) {
      return Scaffold(
        body: StickyFooterScrollView(
          children: [
            loggedIn
                ? const MemberAppBar(activeKey: 'pemilu')
                : const PublicAppBar(activeKey: 'pemilu'),
            const SizedBox(height: 120),
            const Center(child: CircularProgressIndicator()),
            const SiteFooter(),
          ],
        ),
      );
    }

    final candidate = candidates.firstWhere(
      (c) => c.id == candidateId,
      orElse: () => const Candidate(
        id: '',
        nama: '',
        angkatan: null,
        fotoUrl: '',
        visi: '',
        misi: [],
        pengalaman: [],
        voteCount: 0,
        nomorUrut: 0,
      ),
    );

    if (candidate.id.isEmpty) {
      return Scaffold(
        body: StickyFooterScrollView(
          children: [
            loggedIn
                ? const MemberAppBar(activeKey: 'pemilu')
                : const PublicAppBar(activeKey: 'pemilu'),
            SectionWrapper(
              verticalPadding: 80,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: AppColors.gray400),
                    SizedBox(height: 16),
                    Text('Kandidat tidak ditemukan',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SiteFooter(),
          ],
        ),
      );
    }

    SeoHelper.update(
      title: 'Kandidat #${candidate.nomorUrut}: ${candidate.nama}',
      description: _stripHtml(candidate.visi),
      imageUrl: candidate.fotoUrl,
      type: 'profile',
    );

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'pemilu')
              : const PublicAppBar(activeKey: 'pemilu'),
          SectionWrapper(
            verticalPadding: 12,
            maxContentWidth: 1000,
            child: LayoutBuilder(builder: (context, c) {
              final isMobile = c.maxWidth < 640;
              final otherCandidates = candidates.where((c) => c.id != candidate.id).toList();

              // 1. Top Banner Card (Picture or Banner)
              final topBannerCard = Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                clipBehavior: Clip.antiAlias,
                child: isMobile
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: CandidateAvatar(
                              fotoUrl: candidate.fotoUrl,
                              nama: candidate.nama,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Angkatan ${candidate.angkatan}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        candidate.nomorUrut.toString().padLeft(2, '0'),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: candidate.alumniId != null && candidate.alumniId!.isNotEmpty
                                      ? () => context.go('/alumni/${candidate.alumniId}')
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          candidate.nama,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            decoration: candidate.alumniId != null && candidate.alumniId!.isNotEmpty
                                                ? TextDecoration.underline
                                                : TextDecoration.none,
                                            decorationColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (candidate.alumniId != null && candidate.alumniId!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.open_in_new, size: 18, color: Colors.white),
                                      ],
                                    ],
                                  ),
                                ),
                                if (candidate.tagline.isNotEmpty) ...[  
                                  const SizedBox(height: 8),
                                  Text(
                                    '"${candidate.tagline}"',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 220,
                            height: 240,
                            child: CandidateAvatar(
                              fotoUrl: candidate.fotoUrl,
                              nama: candidate.nama,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Angkatan ${candidate.angkatan}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          candidate.nomorUrut.toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: candidate.alumniId != null && candidate.alumniId!.isNotEmpty
                                        ? () => context.go('/alumni/${candidate.alumniId}')
                                        : null,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          candidate.nama,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            decoration: candidate.alumniId != null && candidate.alumniId!.isNotEmpty
                                                ? TextDecoration.underline
                                                : TextDecoration.none,
                                            decorationColor: Colors.white,
                                          ),
                                        ),
                                        if (candidate.alumniId != null && candidate.alumniId!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.open_in_new, size: 22, color: Colors.white),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (candidate.tagline.isNotEmpty) ...[  
                                    const SizedBox(height: 8),
                                    Text(
                                      '"${candidate.tagline}"',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              );

              // 2. Vision & Mission Section (Clean Layout without Card/Border)
              final visiMisiSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CleanSectionHeader(title: 'Visi & Misi'),
                  const SizedBox(height: 16),
                  const Text(
                    '//',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 26,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stripHtml(candidate.visi),
                    style: const TextStyle(
                      color: AppColors.gray700,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...candidate.misi.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final text = entry.value;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            idx.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: AppColors.gray900,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              _stripHtml(text),
                              style: const TextStyle(
                                color: AppColors.gray800,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );

              // 3. Program Kerja Section (Clean Layout without Card/Border)
              final programKerjaList = candidate.programKerja.isNotEmpty
                  ? candidate.programKerja
                  : candidate.pengalaman.map((p) => ProgramKerjaItem(title: p, description: '')).toList();

              final programKerjaSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const _CleanSectionHeader(title: 'Program Kerja'),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    children: programKerjaList.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final p = entry.value;
                      final cardWidth = isMobile ? double.infinity : ((c.maxWidth - 32) / 2).floorToDouble();
                      return SizedBox(
                        width: cardWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$idx',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _stripHtml(p.title),
                              style: const TextStyle(
                                color: AppColors.gray900,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (p.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                _stripHtml(p.description),
                                style: const TextStyle(
                                  color: AppColors.gray400,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );

              // 4. Prestasi Section (Clean Layout without Card/Border)
              final prestasiSection = candidate.prestasi.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const _CleanSectionHeader(title: 'Prestasi'),
                        const SizedBox(height: 20),
                        Column(
                          children: candidate.prestasi.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _stripHtml(item.text),
                                      style: const TextStyle(
                                        color: AppColors.gray800,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (item.year.isNotEmpty)
                                    Text(
                                      item.year,
                                      style: const TextStyle(
                                        color: AppColors.gray500,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  : const SizedBox.shrink();

              // 4. Vote CTA Banner Section
              final voteBannerSection = Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 32, bottom: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 200,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1540910419892-4a36d2c3266c?w=800&q=80',
                              fit: BoxFit.cover,
                              color: Colors.black.withOpacity(0.15),
                              colorBlendMode: BlendMode.darken,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF2D3748),
                                child: const Center(
                                  child: Icon(Icons.how_to_vote, size: 64, color: Colors.white24),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: _VoteBannerContent(loggedIn: loggedIn, hasVoted: hasVoted, candidate: candidate),
                          ),
                        ],
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Image.network(
                                'https://images.unsplash.com/photo-1540910419892-4a36d2c3266c?w=800&q=80',
                                fit: BoxFit.cover,
                                color: Colors.black.withOpacity(0.15),
                                colorBlendMode: BlendMode.darken,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF2D3748),
                                  child: const Center(
                                    child: Icon(Icons.how_to_vote, size: 64, color: Colors.white24),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                                child: _VoteBannerContent(loggedIn: loggedIn, hasVoted: hasVoted, candidate: candidate),
                              ),
                            ),
                          ],
                        ),
                      ),
              );

              // 5. Kandidat Lain Section
              final kandidatLainSection = otherCandidates.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        const _CleanSectionHeader(title: 'Kandidat Lain'),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 32,
                          runSpacing: 32,
                          children: otherCandidates.map((oc) {
                            final cardWidth = isMobile ? double.infinity : ((c.maxWidth - 32) / 2).floorToDouble();
                            return SizedBox(
                              width: cardWidth,
                              child: InkWell(
                                onTap: () => context.go('/pemilu/${oc.id}'),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left: Orange Photo Box
                                    Container(
                                      width: 140,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF97316),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Watermark name in background
                                          Positioned(
                                            right: 8,
                                            top: 40,
                                            child: SizedBox(
                                              width: 90,
                                              child: Text(
                                                oc.nama.split(' ').take(2).join('\n'),
                                                style: TextStyle(
                                                  color: Colors.black.withOpacity(0.12),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.1,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ),
                                          // Candidate Photo
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            top: 24,
                                            child: oc.fotoUrl.isNotEmpty
                                                ? Image.network(
                                                    oc.fotoUrl,
                                                    fit: BoxFit.cover,
                                                    alignment: Alignment.topCenter,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                      Icons.person,
                                                      size: 64,
                                                      color: Colors.white24,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    size: 64,
                                                    color: Colors.white24,
                                                  ),
                                          ),
                                          // Top left number badge "02"
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEA580C),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  bottomRight: Radius.circular(6),
                                                ),
                                              ),
                                              child: Text(
                                                oc.nomorUrut.toString().padLeft(2, '0'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Bottom right blue square dot
                                          Positioned(
                                            bottom: 10,
                                            right: 10,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Right: Info Text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            oc.nama,
                                            style: const TextStyle(
                                              color: AppColors.gray900,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Angkatan ${oc.angkatan}',
                                            style: const TextStyle(
                                              color: AppColors.gray500,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '“${_stripHtml(oc.visi)}”',
                                            style: const TextStyle(
                                              color: AppColors.gray400,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => context.go('/pemilu'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Kembali ke PEMILU',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  topBannerCard,
                  const SizedBox(height: 24),
                  visiMisiSection,
                  programKerjaSection,
                  prestasiSection,
                  const SizedBox(height: 24),
                  voteBannerSection,
                  kandidatLainSection,
                ],
              );
            }),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _CleanSectionHeader extends StatelessWidget {
  final String title;
  const _CleanSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _VoteBannerContent extends StatelessWidget {
  final bool loggedIn;
  final bool hasVoted;
  final Candidate candidate;

  const _VoteBannerContent({
    required this.loggedIn,
    required this.hasVoted,
    required this.candidate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Siap menentukan masa depan\nIKA JTK?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 2,
          color: Colors.white,
        ),
        const SizedBox(height: 12),
        Text(
          'Jika kamu merasa calon ini layak memimpin, berikan dukunganmu sekarang.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (hasVoted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Kamu sudah memberikan suara',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ElevatedButton(
            onPressed: () {
              if (loggedIn) {
                context.go('/pemilu/vote');
              } else {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              loggedIn ? 'Pilih Sekarang' : 'Masuk untuk Memilih',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}