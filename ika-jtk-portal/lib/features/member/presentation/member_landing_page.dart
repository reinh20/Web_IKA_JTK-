import 'package:flutter/material.dart';
import '../../landing/presentation/landing_page.dart';
import 'widgets/member_app_bar.dart';

class MemberLandingPage extends StatelessWidget {
  const MemberLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LandingPage(appBar: MemberAppBar());
  }
}
