import 'package:flutter/material.dart';

class StickyFooterScrollView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const StickyFooterScrollView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // Elemen terakhir dianggap sebagai footer
    final bodyChildren = children.length > 1
        ? children.sublist(0, children.length - 1)
        : <Widget>[];
    final footerChild = children.last;

    return CustomScrollView(
      controller: controller,
      physics: physics,
      slivers: [
        if (padding != null)
          SliverPadding(
            padding: padding!,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: bodyChildren,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: bodyChildren,
            ),
          ),
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: true,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: double.infinity,
              child: footerChild,
            ),
          ),
        ),
      ],
    );
  }
}
