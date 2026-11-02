import 'package:flutter/material.dart';
import '../../../../core/app_config.dart';
import '../../../../shared/widgets/social_share_row.dart';

class AgendaShareRow extends StatelessWidget {
  final String agendaId;
  final String judul;
  const AgendaShareRow({super.key, required this.agendaId, required this.judul});

  @override
  Widget build(BuildContext context) {
    final shareUrl = '${AppConfig.serverHost}/agenda/$agendaId';
    return SocialShareRow(title: judul, customUrl: shareUrl);
  }
}
