import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../app/tokens.dart';
import '../../../../shared/widgets/section_wrapper.dart';
import '../../../member/providers/testimoni_provider.dart';

class TestimonialSection extends ConsumerStatefulWidget {
  const TestimonialSection({super.key});

  @override
  ConsumerState<TestimonialSection> createState() => _TestimonialSectionState();
}

class _TestimonialSectionState extends ConsumerState<TestimonialSection> {
  Timer? _timer;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Start at a high number so we can scroll backward infinitely as well
    _pageController = PageController(initialPage: 1000);
    Future.microtask(() {
      ref.read(testimoniProvider.notifier).fetchPublic();
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final list = ref.read(testimoniProvider).publicList;
      if (list.length > 1 && _pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testimoniProvider);
    final list = state.publicList;

    return SectionWrapper(
      backgroundColor: AppColors.gray50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TESTIMONIAL',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Apa Kata Alumni?',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dengarkan pengalaman alumni yang telah mendapatkan manfaat dari portal alumni IKA JTK Polban.',
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 48),
          if (state.isLoading && list.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (list.isNotEmpty)
            SizedBox(
              height: 250, // Fixed height for carousel to prevent jumping
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  return _buildTestimoniItem(list[index % list.length]);
                },
              ),
            )
          else
            _buildFallbackItem(),
        ],
      ),
    );
  }

  Widget _buildTestimoniItem(Testimoni item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '“${item.isi}”',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.gray700,
            height: 1.6,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            ClipOval(
              child: item.alumniAvatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.alumniAvatarUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildAvatarFallback(),
                    )
                  : _buildAvatarFallback(),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.alumniNama.isNotEmpty ? item.alumniNama : 'Alumni JTK',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.alumniAngkatan.isNotEmpty
                      ? 'Angkatan ${item.alumniAngkatan}'
                      : 'Alumni Polban',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.gray200,
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: AppColors.gray500, size: 24),
    );
  }

  Widget _buildFallbackItem() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '“Masih belum ada testimoni yang di publish. Jadilah yang pertama memberikan testimoni!”',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.gray400,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
