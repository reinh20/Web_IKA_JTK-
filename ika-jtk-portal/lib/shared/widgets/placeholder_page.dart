import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/tokens.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/landing/presentation/widgets/public_app_bar.dart';
import '../../features/landing/presentation/widgets/site_footer.dart';
import '../../features/member/presentation/widgets/member_app_bar.dart';
import 'section_label.dart';
import 'section_wrapper.dart';
import 'sticky_footer_scroll_view.dart';

class SectionPlaceholderPage extends ConsumerWidget {
  final String label;
  final String title;
  final String activeKey;
  const SectionPlaceholderPage({
    super.key,
    required this.label,
    required this.title,
    required this.activeKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? MemberAppBar(activeKey: activeKey)
              : PublicAppBar(activeKey: activeKey),
          SectionWrapper(
            verticalPadding: 64,
            child: SectionLabel(
              label: label,
              title: title,
              description:
                  'Halaman ini sedang dalam pengembangan. Konten lengkap akan tersedia setelah integrasi backend.',
            ),
          ),
          SectionWrapper(
            backgroundColor: AppColors.gray50,
            verticalPadding: 96,
            child: Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.gray100),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Center(
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: AppColors.gray400,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}
