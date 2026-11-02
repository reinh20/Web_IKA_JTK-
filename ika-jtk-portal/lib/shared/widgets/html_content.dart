import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../app/tokens.dart';

/// Renders rich-text HTML content (produced by the CMS TipTap editor) with
/// consistent styling — headings, bold, ordered/bulleted lists, links, etc.
///
/// Used by berita & agenda detail pages so their descriptions render as
/// formatted HTML instead of raw markup.
class HtmlContent extends StatelessWidget {
  final String html;
  final double fontSize;
  final Color? textColor;

  const HtmlContent({
    super.key,
    required this.html,
    this.fontSize = 16,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      html,
      textStyle: TextStyle(
        color: textColor ?? AppColors.gray700,
        fontSize: fontSize,
        height: 1.7,
      ),
      customStylesBuilder: (element) {
        switch (element.localName) {
          case 'a':
            return {'color': '#2563EB'};
          case 'h1':
            return {'font-size': '1.5em', 'font-weight': '700'};
          case 'h2':
            return {'font-size': '1.25em', 'font-weight': '700'};
          case 'h3':
            return {'font-size': '1.1em', 'font-weight': '600'};
          default:
            return null;
        }
      },
    );
  }
}
