import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';

class HowToVoteStep {
  final String title;
  final String description;
  const HowToVoteStep(this.title, this.description);
}

const _steps = <HowToVoteStep>[
  HowToVoteStep('Login ke akun IKA JTK',
      'Pastikan akun kamu sudah terverifikasi sebagai alumni terdaftar.'),
  HowToVoteStep('Pelajari profil kandidat',
      'Baca visi, misi, dan program kerja setiap calon ketua yang tersedia.'),
  HowToVoteStep('Pilih calon yang paling sesuai',
      'Tentukan pilihanmu berdasarkan visi dan gagasan yang paling meyakinkan.'),
  HowToVoteStep('Kirim suara kamu',
      'Konfirmasi pilihan lalu tekan "Kirim Suara". Pilihan tidak dapat diubah setelah dikirim.'),
  HowToVoteStep('Tunggu pengumuman hasil',
      'Hasil resmi akan diumumkan setelah masa pemungutan suara berakhir.'),
];

class HowToVoteSection extends StatelessWidget {
  const HowToVoteSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 0 : 18),
            child: _row(i + 1, _steps[i]),
          ),
      ],
    );
  }

  Widget _row(int number, HowToVoteStep step) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            number.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step.title,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.description,
                style: const TextStyle(
                  color: AppColors.gray600,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
