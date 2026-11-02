import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../providers/loker_provider.dart';
import 'widgets/loker_card.dart';

class LokerListPage extends ConsumerStatefulWidget {
  const LokerListPage({super.key});

  @override
  ConsumerState<LokerListPage> createState() => _LokerListPageState();
}

class _LokerListPageState extends ConsumerState<LokerListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const _jenisOptions = [
    'Semua',
    'Full Time',
    'Part Time',
    'Kontrak',
    'Magang',
    'Freelance',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(lokerProvider.notifier).fetchLoker(loadMore: true);
    }
  }

  void _resetFilters() {
    _searchController.clear();
    ref.read(lokerProvider.notifier).fetchLoker(
      search: '',
      tipePekerjaan: 'Semua',
      kota: 'Semua',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final lokerState = ref.watch(lokerProvider);
    final paged = lokerState.items;

    final defaultLokasi = <String>['Semua', 'Bandung', 'Jakarta', 'Surabaya', 'Remote'];
    final lokasiOpts = {
      ...defaultLokasi,
      if (lokerState.kota.isNotEmpty) lokerState.kota,
      ...paged.map((l) => l.kota).where((k) => k.trim().isNotEmpty && k != '-'),
    }.toList();

    return Scaffold(
      body: StickyFooterScrollView(
        controller: _scrollController,
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'loker')
              : const PublicAppBar(activeKey: 'loker'),
          SectionWrapper(
            verticalPadding: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(
                  label: 'Loker',
                  title: 'Lowongan Kerja Alumni',
                  description:
                      'Temukan peluang kerja dari sesama alumni dan jaringan profesional Teknik Komputer Polban.',
                ),
                const SizedBox(height: 24),
                _FilterBar(
                  searchController: _searchController,
                  jenisFilter: lokerState.tipePekerjaan,
                  jenisOpts: _jenisOptions,
                  lokasiFilter: lokerState.kota,
                  lokasiOpts: lokasiOpts,
                  onSearchChanged: (v) {
                    ref.read(lokerProvider.notifier).fetchLoker(search: v);
                  },
                  onJenisChanged: (v) {
                    ref.read(lokerProvider.notifier).fetchLoker(tipePekerjaan: v ?? 'Semua');
                  },
                  onLokasiChanged: (v) {
                    ref.read(lokerProvider.notifier).fetchLoker(kota: v ?? 'Semua');
                  },
                  onReset: _resetFilters,
                  onApply: () {},
                ),
              ],
            ),
          ),
          SectionWrapper(
            verticalPadding: 16,
            child: (lokerState.isLoading && paged.isEmpty)
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : paged.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text(
                            'Belum ada lowongan tersedia.',
                            style: TextStyle(color: AppColors.gray500),
                          ),
                        ),
                      )
                    : LayoutBuilder(
                    builder: (context, c) {
                      final isMobile = c.maxWidth < AppBreakpoints.tablet;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paged.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 1 : 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 128,
                            ),
                        itemBuilder: (_, i) => LokerCard(item: paged[i]),
                      );
                    },
                  ),
          ),
          
          if (lokerState.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),

          const SizedBox(height: 40),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String jenisFilter;
  final List<String> jenisOpts;
  final String lokasiFilter;
  final List<String> lokasiOpts;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onJenisChanged;
  final ValueChanged<String?> onLokasiChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;
  const _FilterBar({
    required this.searchController,
    required this.jenisFilter,
    required this.jenisOpts,
    required this.lokasiFilter,
    required this.lokasiOpts,
    required this.onSearchChanged,
    required this.onJenisChanged,
    required this.onLokasiChanged,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < AppBreakpoints.mobile;
        final searchField = _LabeledField(
          label: 'Posisi atau Perusahaan',
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: 'Cari posisi atau perusahaan'),
            onChanged: onSearchChanged,
          ),
        );
        final jenisField = _LabeledField(
          label: 'Jenis Pekerjaan',
          child: DropdownButtonFormField<String>(
            initialValue: jenisFilter,
            isExpanded: true,
            items: jenisOpts
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onJenisChanged,
          ),
        );
        final lokasiField = _LabeledField(
          label: 'Lokasi',
          child: DropdownButtonFormField<String>(
            initialValue: lokasiFilter,
            isExpanded: true,
            items: lokasiOpts
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
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
              searchField,
              const SizedBox(height: 12),
              jenisField,
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
            Expanded(flex: 3, child: searchField),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: jenisField),
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

