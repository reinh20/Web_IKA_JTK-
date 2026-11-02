import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_data.dart';

class CandidatePosterCard extends StatelessWidget {
  final Candidate candidate;
  const CandidatePosterCard({super.key, required this.candidate});

  String get _blurb {
    final tag = candidate.tagline.trim();
    if (tag.isNotEmpty) return tag;
    final visi =
        candidate.visi.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
    if (visi.isEmpty) return '';
    final firstSentence = visi.split(RegExp(r'\.(\s|$)')).first.trim();
    return firstSentence.isEmpty ? visi : '$firstSentence.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AspectRatio(
              aspectRatio: 0.95,
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                color: AppColors.accent,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (candidate.fotoUrl.trim().isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          candidate.fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(),
                        ),
                      ),
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        width: 14,
                        height: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 60,
                height: 46,
                alignment: Alignment.center,
                color: AppColors.accent,
                child: Text(
                  candidate.nomorUrut.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: candidate.alumniId != null && candidate.alumniId!.isNotEmpty
              ? () => context.go('/alumni/${candidate.alumniId}')
              : null,
          child: MouseRegion(
            cursor: candidate.alumniId != null && candidate.alumniId!.isNotEmpty
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: Text(
              candidate.nama,
              style: TextStyle(
                color: candidate.alumniId != null && candidate.alumniId!.isNotEmpty
                    ? AppColors.primary
                    : AppColors.gray900,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                decoration: candidate.alumniId != null && candidate.alumniId!.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Angkatan ${candidate.angkatan}',
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: 12,
          ),
        ),
        if (_blurb.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            '"$_blurb"',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray600,
              fontSize: 12.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 12),
        InkWell(
          onTap: () => context.go('/pemilu/${candidate.id}'),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat Program Kerja',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}
