import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../../../app/tokens.dart';
import '../../../../core/portal_config_provider.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/section_wrapper.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final about = ref.watch(portalConfigProvider).valueOrNull?.about ?? const AboutSectionData();
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.tablet;
    final rawContent = about.content.isNotEmpty
        ? about.content
        : '<p>IKA JTK Polban adalah ikatan para alumni lulusan dari jurusan Teknik Komputer dan Informatika Politeknik Negeri Bandung. IKA JTK merupakan organisasi yang dapat mewadahi dan memfasilitasi seluruh alumni JTK Polban, sehingga dapat menciptakan serta menjaga hubungan yang harmonis berdasarkan asas kekeluargaan dan kebersamaan antar alumni. IKA JTK juga diberikan agar para alumni dapat berinteraksi dan berkolaborasi untuk mencapai suatu tujuan tertentu. Selain itu, IKA JTK dapat menghimpun dan menyampaikan aspirasi alumni — alumni dari Jurusan Teknik Komputer dan Informatika Politeknik Negeri Bandung.</p>';

    Color parseHexColor(String hexString) {
      try {
        if (hexString.isEmpty) return AppColors.peach;
        final cleanHex = hexString.replaceFirst('#', '');
        if (cleanHex.length == 6) {
          final r = int.parse(cleanHex.substring(0, 2), radix: 16);
          final g = int.parse(cleanHex.substring(2, 4), radix: 16);
          final b = int.parse(cleanHex.substring(4, 6), radix: 16);
          return Color.fromRGBO(r, g, b, 1.0);
        } else if (cleanHex.length == 8) {
          final a = int.parse(cleanHex.substring(0, 2), radix: 16) / 255.0;
          final r = int.parse(cleanHex.substring(2, 4), radix: 16);
          final g = int.parse(cleanHex.substring(4, 6), radix: 16);
          final b = int.parse(cleanHex.substring(6, 8), radix: 16);
          return Color.fromRGBO(r, g, b, a);
        }
        return AppColors.peach;
      } catch (_) {
        return AppColors.peach;
      }
    }

    return SectionWrapper(
      backgroundColor: parseHexColor(about.bgColor),
      verticalPadding: 64,
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: SectionLabel(
              label: about.label,
              title: about.title,
              align: CrossAxisAlignment.start,
            ),
          ),
          SizedBox(width: isMobile ? 0 : 48, height: isMobile ? 24 : 0),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: HtmlWidget(
              rawContent,
              textStyle: const TextStyle(
                color: AppColors.gray700,
                fontSize: 14,
                height: 1.7,
              ),
              customStylesBuilder: (element) {
                if (element.localName == 'a') {
                  return {'color': '#1E88E5', 'text-decoration': 'underline'};
                }
                if (element.localName == 'ol' || element.localName == 'ul') {
                  return {'padding-left': '20px'};
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
