import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/tokens.dart';
import '../../../core/portal_config_provider.dart';
import '../../../shared/widgets/html_content.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';

class UserAgreementsPage extends ConsumerStatefulWidget {
  const UserAgreementsPage({super.key});

  @override
  ConsumerState<UserAgreementsPage> createState() => _UserAgreementsPageState();
}

class _UserAgreementsPageState extends ConsumerState<UserAgreementsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(portalConfigProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final config = ref.watch(portalConfigProvider);
    final terms = config.valueOrNull?.termsConditions ?? const TermsConditionsData();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: StickyFooterScrollView(
        children: [
          loggedIn
              ? const MemberAppBar(activeKey: '')
              : const PublicAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 48,
            maxContentWidth: 1000,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SYARAT & KETENTUAN PENGGUNA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  terms.title,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (terms.lastUpdated.isNotEmpty || terms.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    terms.lastUpdated.isNotEmpty && terms.subtitle.isNotEmpty
                        ? 'Terakhir diperbarui: ${terms.lastUpdated}. ${terms.subtitle}'
                        : terms.lastUpdated.isNotEmpty
                            ? 'Terakhir diperbarui: ${terms.lastUpdated}'
                            : terms.subtitle,
                    style: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Content Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _buildTermsAndConditions(terms),
                ),
              ],
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions(TermsConditionsData terms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderSection(
          icon: Icons.gavel,
          title: terms.title,
          subtitle: terms.subtitle,
        ),
        const SizedBox(height: 24),
        if (terms.intro.isNotEmpty) ...[
          HtmlContent(
            html: terms.intro,
            fontSize: 15,
            textColor: AppColors.gray700,
          ),
          const SizedBox(height: 24),
        ],
        HtmlContent(
          html: terms.content,
          fontSize: 15,
          textColor: AppColors.gray700,
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeaderSection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gray600,
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

