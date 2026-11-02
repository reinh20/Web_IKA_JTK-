import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_data.dart';
import 'candidate_avatar.dart';

class CandidateRadioTile extends StatelessWidget {
  final Candidate candidate;
  final bool selected;
  final ValueChanged<String> onSelect;

  const CandidateRadioTile({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onSelect,
  });

  String get _blurb {
    final tag = candidate.tagline.trim();
    if (tag.isNotEmpty) return tag;
    final visi = candidate.visi.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
    if (visi.isEmpty) return '';
    final firstSentence = visi.split(RegExp(r'\.(\s|$)')).first.trim();
    return firstSentence.isEmpty ? visi : '$firstSentence.';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelect(candidate.id),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12, top: 10),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.gray400,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      candidate.nama,
                      style: const TextStyle(
                        color: AppColors.gray900,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
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
                      const SizedBox(height: 8),
                      Text(
                        '"$_blurb"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 84,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CandidateAvatar(
                      fotoUrl: candidate.fotoUrl,
                      nama: candidate.nama,
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    left: 6,
                    child: Text(
                      candidate.nama,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
