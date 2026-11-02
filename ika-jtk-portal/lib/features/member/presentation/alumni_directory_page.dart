import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/tokens.dart';
import '../../../core/portal_data.dart';
import '../../../shared/widgets/portal_network_image.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../providers/alumni_provider.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import 'widgets/featured_alumni_banner.dart';
import 'widgets/member_app_bar.dart';
import '../../auth/providers/auth_provider.dart';

class AlumniDirectoryPage extends ConsumerStatefulWidget {
  const AlumniDirectoryPage({super.key});

  @override
  ConsumerState<AlumniDirectoryPage> createState() =>
      _AlumniDirectoryPageState();
}

class _AlumniDirectoryPageState extends ConsumerState<AlumniDirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
      ref.read(alumniProvider.notifier).fetchAlumni(loadMore: true);
    }
  }

  void _resetFilter() {
    _searchController.clear();
    ref.read(alumniProvider.notifier).fetchAlumni(
      search: '',
      angkatan: 'Semua',
    );
  }

  @override
  Widget build(BuildContext context) {
    final alumniState = ref.watch(alumniProvider);
    final allAlumni = alumniState.items;
    final isLoading = alumniState.isLoading && allAlumni.isEmpty;

    final list = allAlumni;
    final angkatanOpts = alumniState.angkatanOpts;
    final totalPages = (alumniState.total / 12).ceil();

    return Scaffold(
      body: StickyFooterScrollView(
        controller: _scrollController,
        children: [
          const MemberAppBar(activeKey: ''),
          const SectionWrapper(
            verticalPadding: 24,
            child: FeaturedAlumniBanner(),
          ),
          SectionWrapper(
            verticalPadding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(
                  label: 'Alumni',
                  title: 'Direktori Alumni',
                  description:
                      'Temukan dan terhubung dengan alumni IKA JTK Polban dari berbagai angkatan dan latar belakang karier.',
                ),
                const SizedBox(height: 24),
                _FilterBar(
                  searchController: _searchController,
                  angkatanFilter: alumniState.angkatan,
                  angkatanOpts: angkatanOpts,
                  onSearchChanged: (v) {
                    ref.read(alumniProvider.notifier).fetchAlumni(search: v);
                  },
                  onAngkatanChanged: (v) {
                    ref.read(alumniProvider.notifier).fetchAlumni(angkatan: v ?? 'Semua');
                  },
                  onReset: _resetFilter,
                  onApply: () {},
                ),
              ],
            ),
          ),
          SectionWrapper(
            verticalPadding: 16,
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 48,
                            color: AppColors.gray300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada data alumni',
                            style: TextStyle(
                              color: AppColors.gray500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, c) {
                          final isMobile = c.maxWidth < AppBreakpoints.tablet;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isMobile ? 2 : 4,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 24,
                                  childAspectRatio: 0.72,
                                ),
                            itemBuilder: (_, i) => _AlumniCard(item: list[i]),
                          );
                        },
                      ),
                      
                      if (alumniState.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 80),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String angkatanFilter;
  final List<String> angkatanOpts;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onAngkatanChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;
  const _FilterBar({
    required this.searchController,
    required this.angkatanFilter,
    required this.angkatanOpts,
    required this.onSearchChanged,
    required this.onAngkatanChanged,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < AppBreakpoints.mobile;
        final fields = [
          Expanded(
            flex: 2,
            child: _LabeledField(
              label: 'Nama',
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(hintText: 'Cari Nama'),
                onChanged: onSearchChanged,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _LabeledField(
              label: 'Angkatan',
              child: DropdownButtonFormField<String>(
                initialValue: angkatanFilter,
                isExpanded: true,
                items: angkatanOpts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a,
                        child: Text(
                          a == 'Semua' ? 'Semua' : a,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onAngkatanChanged,
              ),
            ),
          ),
        ];
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
              _LabeledField(
                label: 'Nama',
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(hintText: 'Cari Nama'),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Angkatan',
                child: DropdownButtonFormField<String>(
                  initialValue: angkatanFilter,
                  isExpanded: true,
                  items: angkatanOpts
                      .map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a == 'Semua' ? 'Semua' : a),
                        ),
                      )
                      .toList(),
                  onChanged: onAngkatanChanged,
                ),
              ),
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
            ...fields,
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

class _AlumniCard extends ConsumerWidget {
  final AlumniDirEntry item;
  const _AlumniCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final isOwnProfile = currentUser?.id == item.id;
    final isAlumni = item.keanggotaan.toLowerCase() == 'alumni';
    final badgeText = item.keanggotaan;
    final chipColor = isAlumni ? AppColors.gray500 : AppColors.accent;

    final posisi = item.posisiSekarang.trim();
    final perusahaan = item.perusahaan.trim();
    final jobLine = [
      posisi,
      perusahaan,
    ].where((s) => s.isNotEmpty).join(' , ');

    return InkWell(
      onTap: () => context.go('/member/alumni/${item.id}'),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: PortalNetworkImage(
                      url: item.fotoUrl,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.person_outline,
                    ),
                  ),
                ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray900,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isOwnProfile && item.noAlumni != null) ...[
            const SizedBox(height: 4),
            Text(
              '#${item.noAlumni}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            item.angkatan == null ? '-' : 'Angkatan ${item.angkatan}',
            style: const TextStyle(color: AppColors.gray500, fontSize: 11),
          ),
          if (jobLine.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              jobLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.gray700, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
