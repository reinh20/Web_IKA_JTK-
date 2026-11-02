import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/format_utils.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../auth/providers/auth_provider.dart';
import 'widgets/member_app_bar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      body: ListView(
        children: [
          const MemberAppBar(activeKey: ''),
          SectionWrapper(
            backgroundColor: AppColors.gray50,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.gray100),
              ),
              child: Row(
                children: [
                  if (user != null)
                    Builder(builder: (context) {
                      final finalUrl = resolveThumbnailUrl(user.avatarUrl);
                      return ClipOval(
                        child: user.avatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: finalUrl.startsWith('/')
                                    ? '${AuthController.serverHost}$finalUrl'
                                    : finalUrl,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 96,
                                  height: 96,
                                  color: AppColors.gray200,
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.gray500,
                                    size: 48,
                                  ),
                                ),
                              )
                            : Container(
                                width: 96,
                                height: 96,
                                color: AppColors.gray200,
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.gray500,
                                  size: 48,
                                ),
                              ),
                      );
                    }),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nama ?? 'Tamu',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: AppColors.gray600),
                        ),
                        const SizedBox(height: 4),
                        if (user != null)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Angkatan ${user.angkatan}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SectionWrapper(
            backgroundColor: AppColors.gray50,
            verticalPadding: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(bottom: 80),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.gray100),
              ),
              child: const Text(
                'Halaman profile lengkap akan tersedia setelah integrasi backend.',
                style: TextStyle(color: AppColors.gray500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
