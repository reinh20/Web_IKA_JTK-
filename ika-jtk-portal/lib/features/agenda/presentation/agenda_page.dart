import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/portal_data.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../providers/agenda_provider.dart';
import 'widgets/agenda_filter_bar.dart';
import 'widgets/agenda_hero_carousel.dart';
import 'widgets/agenda_row_card.dart';

const int _kHeroCount = 3;

class AgendaListPage extends ConsumerStatefulWidget {
  const AgendaListPage({super.key});

  @override
  ConsumerState<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends ConsumerState<AgendaListPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _lokasiController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(agendaProvider.notifier).fetchAgenda(loadMore: true);
    }
  }

  void _resetFilters() {
    _searchController.clear();
    _lokasiController.clear();
    ref.read(agendaProvider.notifier).fetchAgenda(
      search: '',
      lokasi: '',
      waktuFilter: 'Semua',
    );
  }

  bool _isUpcoming(AgendaContent a) {
    final dt = DateTime.tryParse(a.tanggalEventRaw);
    if (dt == null) return true;
    return dt.toLocal().isAfter(DateTime.now());
  }

  List<AgendaContent> _sortedUpcoming(List<AgendaContent> all) {
    final upcoming = all.where(_isUpcoming).toList();
    upcoming.sort((a, b) {
      final da = DateTime.tryParse(a.tanggalEventRaw) ?? DateTime(2100);
      final db = DateTime.tryParse(b.tanggalEventRaw) ?? DateTime(2100);
      return da.compareTo(db);
    });
    return upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final agendaState = ref.watch(agendaProvider);
    final list = List<AgendaContent>.from(agendaState.items);
    
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    list.sort((a, b) {
      final dateA = DateTime.tryParse(a.tanggalEventRaw) ?? DateTime(0);
      final dateB = DateTime.tryParse(b.tanggalEventRaw) ?? DateTime(0);
      
      final isFutureA = !dateA.isBefore(today);
      final isFutureB = !dateB.isBefore(today);
      
      if (isFutureA && isFutureB) {
        return dateA.compareTo(dateB);
      } else if (!isFutureA && !isFutureB) {
        return dateB.compareTo(dateA);
      } else {
        return isFutureA ? -1 : 1;
      }
    });

    final heroItems = agendaState.heroItems.isNotEmpty
        ? agendaState.heroItems
        : _sortedUpcoming(list).take(_kHeroCount).toList();

    final paged = list;

    return Scaffold(
      body: StickyFooterScrollView(
        controller: _scrollController,
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: 'agenda')
              : const PublicAppBar(activeKey: 'agenda'),
          if (heroItems.isNotEmpty)
            SectionWrapper(
              verticalPadding: 40,
              child: AgendaHeroCarousel(items: heroItems),
            ),
          SectionWrapper(
            verticalPadding: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(
                  label: 'Agenda',
                  title: 'Agenda & Kegiatan IKA JTK Polban',
                  description:
                      'Terus ikuti berbagai acara, reuni, seminar, dan kegiatan menarik lainnya yang mempererat komunitas alumni.',
                ),
                const SizedBox(height: 24),
                AgendaFilterBar(
                  searchController: _searchController,
                  lokasiController: _lokasiController,
                  waktuFilter: agendaState.waktuFilter,
                  waktuOpts: const ['Semua', 'Upcoming', 'Past'],
                  onSearchChanged: (v) {
                    ref.read(agendaProvider.notifier).fetchAgenda(search: v);
                  },
                  onWaktuChanged: (v) {
                    ref.read(agendaProvider.notifier).fetchAgenda(waktuFilter: v ?? 'Semua');
                  },
                  onLokasiChanged: (v) {
                    ref.read(agendaProvider.notifier).fetchAgenda(lokasi: v);
                  },
                  onReset: _resetFilters,
                  onApply: () {},
                ),
              ],
            ),
          ),
          SectionWrapper(
            verticalPadding: 16,
            child: (agendaState.isLoading && paged.isEmpty)
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : paged.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: EmptyState(
                          icon: Icons.event_busy_outlined,
                          title: 'Tidak ada agenda',
                          message:
                              'Tidak ada agenda yang cocok dengan filter Anda. Coba ubah filter atau hapus semua filter.',
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paged.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => AgendaRowCard(item: paged[i]),
                      ),
          ),
          
          if (agendaState.isLoadingMore)
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
