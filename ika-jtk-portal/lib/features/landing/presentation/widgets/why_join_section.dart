import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_config_provider.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/section_wrapper.dart';

class WhyJoinSection extends ConsumerWidget {
  final bool showCtaButton;
  const WhyJoinSection({super.key, this.showCtaButton = true});

  IconData _iconFor(String key) {
    switch (key) {
      case 'network':
        return Icons.share_outlined;
      case 'briefcase':
        return Icons.work_outline;
      case 'calendar':
        return Icons.calendar_today_outlined;
      case 'photo':
        return Icons.photo_library_outlined;
      default:
        return Icons.star_outline;
    }
  }

  List<_DefaultFeature> _defaultFeatures() {
    return const [
      _DefaultFeature(iconKey: 'network', judul: 'Jejaring Alumni', deskripsi: 'Bangun koneksi profesional lintas angkatan.'),
      _DefaultFeature(iconKey: 'briefcase', judul: 'Lowongan Kerja', deskripsi: 'Temukan peluang karier yang dibagikan alumni.'),
      _DefaultFeature(iconKey: 'calendar', judul: 'Agenda Alumni', deskripsi: 'Ikuti kegiatan alumni dan reuni.'),
      _DefaultFeature(iconKey: 'photo', judul: 'Galeri & Cerita', deskripsi: 'Momen bersama melalui foto dan testimoni alumni.'),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(portalConfigProvider).valueOrNull?.features ?? [];
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.tablet;

    final items = features.isNotEmpty
        ? features.map((f) => _FeatureCard(icon: _iconFor(f.iconKey), judul: f.judul, deskripsi: f.deskripsi)).toList()
        : _defaultFeatures().map((f) => _FeatureCard(icon: _iconFor(f.iconKey), judul: f.judul, deskripsi: f.deskripsi)).toList();

    return SectionWrapper(
      backgroundColor: AppColors.gray50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            label: 'Fungsi Portal IKA JTK',
            title: 'Kenapa Harus Join?',
            description: 'Manfaat Menjadi Bagian dari IKA JTK',
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 4 : 4.5,
            children: items,
          ),
          if (showCtaButton) ...[
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => context.go('/register'),
              child: const Text('Gabung Sekarang'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DefaultFeature {
  final String iconKey;
  final String judul;
  final String deskripsi;
  const _DefaultFeature({required this.iconKey, required this.judul, required this.deskripsi});
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String deskripsi;
  const _FeatureCard({required this.icon, required this.judul, required this.deskripsi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  judul.stripHtml,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.gray900),
                ),
                const SizedBox(height: 4),
                Text(
                  deskripsi.stripHtml,
                  style: const TextStyle(fontSize: 13, color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
