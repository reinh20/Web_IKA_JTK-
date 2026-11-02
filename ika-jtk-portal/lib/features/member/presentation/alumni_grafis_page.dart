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
import 'widgets/member_app_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';

class AlumniGrafisPage extends ConsumerStatefulWidget {
  const AlumniGrafisPage({super.key});

  @override
  ConsumerState<AlumniGrafisPage> createState() => _AlumniGrafisPageState();
}

class _AlumniGrafisPageState extends ConsumerState<AlumniGrafisPage> {
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alumniGrafisProvider.notifier).fetchAlumni(
        search: '',
        angkatan: 'Semua',
      );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(alumniGrafisProvider.notifier).fetchAlumni(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilter() {
    _searchController.clear();
    ref.read(alumniGrafisProvider.notifier).fetchAlumni(
      search: '',
      angkatan: 'Semua',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final alumniState = ref.watch(alumniGrafisProvider);
    
    final list = alumniState.items;
    final isLoading = alumniState.isLoading && list.isEmpty;
    final angkatanOpts = alumniState.angkatanOpts;

    return Scaffold(
      body: StickyFooterScrollView(
        controller: _scrollController,
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'alumnigrafis')
              : const PublicAppBar(activeKey: 'alumnigrafis'),
          SectionWrapper(
            verticalPadding: 32,
            maxContentWidth: 1100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ALUMNI GRAFIS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Notable Alumni IKA JTK Polban',
                  style: TextStyle(
                    color: AppColors.gray900,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 40, height: 3, color: AppColors.accent),
                const SizedBox(height: 32),
                const _HeroBanner(),
              ],
            ),
          ),
          SectionWrapper(
            verticalPadding: 16,
            maxContentWidth: 1100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(
                  label: 'Daftar Notable',
                  title: 'Alumni Public Figure & Berprestasi',
                  description:
                      'Temukan profil alumni dengan pencapaian membanggakan baik di kancah nasional maupun internasional.',
                ),
                const SizedBox(height: 24),
                _FilterBar(
                  searchController: _searchController,
                  angkatanFilter: alumniState.angkatan,
                  angkatanOpts: angkatanOpts,
                  onSearchChanged: (v) {
                    ref.read(alumniGrafisProvider.notifier).fetchAlumni(search: v);
                  },
                  onAngkatanChanged: (v) {
                    ref.read(alumniGrafisProvider.notifier).fetchAlumni(angkatan: v ?? 'Semua');
                  },
                  onReset: _resetFilter,
                  onApply: () {},
                ),
              ],
            ),
          ),
          SectionWrapper(
            verticalPadding: 16,
            maxContentWidth: 1100,
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
                            Icons.star_outline,
                            size: 48,
                            color: AppColors.gray300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada data alumni grafis',
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
                            itemBuilder: (context, index) {
                              return _AlumniCard(item: list[index]);
                            },
                          );
                        },
                      ),
                      if (alumniState.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.only(top: 24.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),const SizedBox(height: 80),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 6,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.navy),
                const PortalNetworkImage(
                  url: 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=2000&q=80',
                  fit: BoxFit.cover,
                  backgroundColor: AppColors.navy,
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isMobile ? 16 : 24,
                      left: isMobile ? 16 : 32,
                    ),
                    child: Text(
                      'Menorehkan Prestasi, Menginspirasi Generasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
        final isMobile = c.maxWidth < 600;
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
    final kategori = item.alumniGrafis?['kategori']?.toString() ?? '';
    final isPrestasi = kategori.toLowerCase().contains('prestasi');
    final chipColor = isPrestasi ? Colors.amber[700]! : AppColors.primary;
    final description = item.alumniGrafis?['description']?.toString() ?? '';
    final isAlumni = item.keanggotaan.toLowerCase() == 'alumni';
    final keanggotaanText = item.keanggotaan;
    final chipText = description.isNotEmpty ? description : (kategori.isNotEmpty ? kategori : keanggotaanText);

    return InkWell(
      onTap: () => context.go('/member/alumni/${item.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PortalNetworkImage(
                url: item.fotoUrl,
                fit: BoxFit.cover,
                placeholderIcon: Icons.person_outline,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.nama,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),
          Text(
            item.angkatan == null ? '-' : 'JTK ${item.angkatan}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gray500, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (chipText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                chipText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: chipColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
