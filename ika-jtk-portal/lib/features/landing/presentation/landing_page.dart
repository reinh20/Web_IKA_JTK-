import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import 'widgets/public_app_bar.dart';
import 'widgets/hero_carousel.dart';
import 'widgets/about_section.dart';
import 'widgets/latest_news_section.dart';
import 'widgets/agenda_section.dart';
import 'widgets/why_join_section.dart';
import 'widgets/testimonial_section.dart';
import 'widgets/faq_section.dart';
import 'widgets/cta_section.dart';
import 'widgets/site_footer.dart';

class LandingPage extends StatefulWidget {
  final Widget appBar;
  const LandingPage({super.key, required this.appBar});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey _tentangKey = GlobalKey();
  final GlobalKey _beritaKey = GlobalKey();
  final GlobalKey _agendaKey = GlobalKey();
  final GlobalKey _kenapaKey = GlobalKey();
  final GlobalKey _testimoniKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  late final Map<String, GlobalKey> _sectionKeys = {
    'tentang': _tentangKey,
    'about': _tentangKey,
    'berita': _beritaKey,
    'news': _beritaKey,
    'agenda': _agendaKey,
    'event': _agendaKey,
    'kenapa': _kenapaKey,
    'join': _kenapaKey,
    'testimoni': _testimoniKey,
    'faq': _faqKey,
    'tanya': _faqKey,
    'cta': _ctaKey,
  };

  String _lastScrolledSection = '';
  String _initialHash = '';

  @override
  void initState() {
    super.initState();
    try {
      _initialHash = html.window.location.hash.replaceAll('#', '').toLowerCase();
      if (_initialHash.isEmpty) {
        _initialHash = Uri.base.fragment.toLowerCase();
      }
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndScrollToSection();
    });

    html.window.onHashChange.listen((_) {
      _checkAndScrollToSection(force: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String targetFromQuery = '';
    try {
      final uri = GoRouterState.of(context).uri;
      targetFromQuery = (uri.queryParameters['section'] ?? '').toLowerCase();
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndScrollToSection(queryTarget: targetFromQuery);
    });
  }

  void _checkAndScrollToSection({bool force = false, String? queryTarget}) {
    try {
      var target = html.window.location.hash.replaceAll('#', '').toLowerCase();
      if (target.isEmpty) {
        target = Uri.base.fragment.toLowerCase();
      }

      var queryTargetValue = queryTarget ?? '';
      if (queryTargetValue.isEmpty) {
        queryTargetValue = (Uri.base.queryParameters['section'] ?? '').toLowerCase();
      }

      if (target.isEmpty && queryTargetValue.isNotEmpty) {
        target = queryTargetValue;
      }

      if (target.isEmpty && _initialHash.isNotEmpty) {
        target = _initialHash;
      }

      if (target.isEmpty) return;
      if (!force && _lastScrolledSection == target) return;

      final targetKey = _sectionKeys[target];

      if (targetKey?.currentContext != null) {
        _lastScrolledSection = target;
        Scrollable.ensureVisible(
          targetKey!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && targetKey.currentContext != null) {
            Scrollable.ensureVisible(
              targetKey.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          widget.appBar,
          const HeroCarousel(),
          KeyedSubtree(key: _tentangKey, child: const AboutSection()),
          KeyedSubtree(key: _beritaKey, child: const LatestNewsSection()),
          KeyedSubtree(key: _agendaKey, child: const AgendaSection()),
          KeyedSubtree(key: _kenapaKey, child: const WhyJoinSection()),
          KeyedSubtree(key: _testimoniKey, child: const TestimonialSection()),
          KeyedSubtree(key: _faqKey, child: const FaqSection()),
          KeyedSubtree(key: _ctaKey, child: const CtaSection()),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class PublicLandingPage extends StatelessWidget {
  const PublicLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LandingPage(appBar: PublicAppBar());
  }
}
