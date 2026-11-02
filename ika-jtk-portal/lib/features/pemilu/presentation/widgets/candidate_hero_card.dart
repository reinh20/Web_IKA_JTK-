import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_data.dart';
import 'candidate_avatar.dart';

class CandidateHeroCard extends StatelessWidget {
  final Candidate candidate;
  const CandidateHeroCard({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < AppBreakpoints.tablet;
    final content = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 260,
                child: CandidateAvatar(
                  fotoUrl: candidate.fotoUrl,
                  nama: candidate.nama,
                ),
              ),
              _textPanel(context),
            ],
          )
        : SizedBox(
            height: 300,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 260,
                  child: CandidateAvatar(
                    fotoUrl: candidate.fotoUrl,
                    nama: candidate.nama,
                  ),
                ),
                Expanded(child: _textPanel(context)),
              ],
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        color: AppColors.accent,
        child: content,
      ),
    );
  }

  Widget _textPanel(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                candidate.nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              if (candidate.tagline.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '"${candidate.tagline}"',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              candidate.nomorUrut.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
