import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_config_provider.dart';
import '../../../../shared/widgets/html_content.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/section_wrapper.dart';

class FaqSection extends ConsumerStatefulWidget {
  const FaqSection({super.key});

  @override
  ConsumerState<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends ConsumerState<FaqSection> {
  final Set<int> _expanded = {0};

  @override
  Widget build(BuildContext context) {
    final faqs = ref.watch(portalConfigProvider).valueOrNull?.faqs ?? [];
    final items = faqs.map((f) => _FaqData(pertanyaan: f.pertanyaan, jawaban: f.jawaban)).toList();

    return SectionWrapper(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            label: 'FAQ',
            title: 'Frequently Asked Question',
            description: 'Dengarkan pengalaman alumni yang telah mendapatkan manfaat dari portal IKA JTK Polban.',
          ),
          const SizedBox(height: 32),
          items.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 48,
                        color: AppColors.gray400,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada FAQ yang masuk',
                        style: TextStyle(
                          color: AppColors.gray700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final faq = entry.value;
                    final open = _expanded.contains(i);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.gray100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () => setState(() {
                              open ? _expanded.remove(i) : _expanded.add(i);
                            }),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text('?', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 13)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      faq.pertanyaan,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    duration: const Duration(milliseconds: 200),
                                    turns: open ? 0.5 : 0,
                                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.gray500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (open)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(60, 0, 20, 20),
                              child: HtmlContent(
                                html: faq.jawaban,
                                fontSize: 13.5,
                                textColor: AppColors.gray600,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

class _FaqData {
  final String pertanyaan;
  final String jawaban;
  const _FaqData({required this.pertanyaan, required this.jawaban});
}
