import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/tokens.dart';
import '../../../../core/format_utils.dart';
import '../../../../core/portal_data.dart';
import '../../../../shared/widgets/portal_network_image.dart';

class LokerCard extends StatelessWidget {
  final LokerContent item;
  const LokerCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/loker/${item.id}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompanyIcon(logoUrl: item.logoUrl, name: item.namaPerusahaan),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.posisi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray900,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _companyLine(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (item.jenisPekerjaan.isNotEmpty)
                              Pill(
                                label: item.jenisPekerjaan,
                                bg: AppColors.primaryLight,
                                fg: AppColors.primary,
                              ),
                            if (item.tipeLokasi.isNotEmpty)
                              Pill(
                                label: item.tipeLokasi,
                                bg: AppColors.accentLight,
                                fg: AppColors.accentDark,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRelativeTime(item.createdAtRaw),
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _companyLine() {
    final parts = [item.namaPerusahaan, item.kota]
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.join(' · ');
  }
}

class CompanyIcon extends StatelessWidget {
  final String logoUrl;
  final String name;
  final double size;
  const CompanyIcon({
    super.key,
    required this.logoUrl,
    required this.name,
    this.size = 64,
  });

  static const _palette = [
    AppColors.primary,
    AppColors.accent,
    AppColors.navy,
    AppColors.success,
    AppColors.danger,
    AppColors.primaryDark,
    AppColors.accentDark,
  ];

  Color get _bg {
    if (name.isEmpty) return AppColors.primary;
    return _palette[name.hashCode.abs() % _palette.length];
  }

  String get _initial => name.isEmpty ? '?' : name[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final child = logoUrl.isNotEmpty
        ? PortalNetworkImage(
            url: logoUrl,
            fit: BoxFit.cover,
            placeholderIcon: Icons.business,
          )
        : Container(
            color: _bg,
            alignment: Alignment.center,
            child: Text(
              _initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const Pill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
