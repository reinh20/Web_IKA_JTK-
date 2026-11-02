import 'package:flutter/material.dart';
import '../../app/tokens.dart';

class SectionWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double verticalPadding;
  final double maxContentWidth;

  const SectionWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
    this.verticalPadding = 80,
    this.maxContentWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < AppBreakpoints.tablet ? 24.0 : 48.0;

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: child,
        ),
      ),
    );
  }
}
