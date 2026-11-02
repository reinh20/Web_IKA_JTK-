import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';

class AgendaFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController lokasiController;
  final String waktuFilter;
  final List<String> waktuOpts;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onWaktuChanged;
  final ValueChanged<String> onLokasiChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const AgendaFilterBar({
    super.key,
    required this.searchController,
    required this.lokasiController,
    required this.waktuFilter,
    required this.waktuOpts,
    required this.onSearchChanged,
    required this.onWaktuChanged,
    required this.onLokasiChanged,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < AppBreakpoints.mobile;
        final nameField = _LabeledField(
          label: 'Nama',
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: 'Cari nama agenda'),
            onChanged: onSearchChanged,
          ),
        );
        final waktuField = _LabeledField(
          label: 'Waktu',
          child: DropdownButtonFormField<String>(
            initialValue: waktuFilter,
            isExpanded: true,
            items: waktuOpts
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onWaktuChanged,
          ),
        );
        final lokasiField = _LabeledField(
          label: 'Lokasi',
          child: TextField(
            controller: lokasiController,
            decoration: const InputDecoration(hintText: 'Cari lokasi agenda'),
            onChanged: onLokasiChanged,
          ),
        );
        final buttons = [
          TextButton(
            onPressed: onReset,
            child: const Text(
              'Hapus Filter',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('Terapkan'),
          ),
        ];

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              nameField,
              const SizedBox(height: 12),
              waktuField,
              const SizedBox(height: 12),
              lokasiField,
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: buttons,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 3, child: nameField),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: waktuField),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: lokasiField),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
            ),
          ],
        );
      },
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gray700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
