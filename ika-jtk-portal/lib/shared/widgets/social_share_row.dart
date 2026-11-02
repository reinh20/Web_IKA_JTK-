import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/tokens.dart';
import '../../core/app_config.dart';

class SocialShareRow extends StatelessWidget {
  final String title;
  final String? customUrl;

  const SocialShareRow({
    super.key,
    required this.title,
    this.customUrl,
  });

  String get _effectiveUrl {
    if (customUrl != null && customUrl!.isNotEmpty) {
      return customUrl!;
    }
    String path = Uri.base.fragment.isNotEmpty ? Uri.base.fragment : Uri.base.path;
    if (!path.startsWith('/')) path = '/$path';

    if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
      return '${AppConfig.serverHost}$path';
    }
    final portPart = Uri.base.hasPort && Uri.base.port != 80 && Uri.base.port != 443 ? ':${Uri.base.port}' : '';
    return '${Uri.base.scheme}://${Uri.base.host}$portPart$path';
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _shareToInstagram(BuildContext context) async {
    final url = _effectiveUrl;
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tautan disalin! Mengalihkan ke Instagram untuk dibagikan ke Story/DM...'),
        duration: Duration(seconds: 3),
      ),
    );
    // Buka Instagram
    final uri = Uri.parse('https://www.instagram.com/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleEnc = Uri.encodeComponent(title);
    final urlEnc = Uri.encodeComponent(_effectiveUrl);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        const Text(
          'Bagikan ke:',
          style: TextStyle(color: AppColors.gray600, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        // 1. X (Twitter)
        _ShareIconBtn(
          tooltip: 'Bagikan ke X (Twitter)',
          background: const Color(0xFF000000),
          onTap: () => _openUrl('https://twitter.com/intent/tweet?text=$titleEnc&url=$urlEnc'),
          child: const Text(
            '𝕏',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // 2. Facebook
        _ShareIconBtn(
          tooltip: 'Bagikan ke Facebook',
          background: const Color(0xFF1877F2),
          onTap: () => _openUrl('https://www.facebook.com/sharer/sharer.php?u=$urlEnc'),
          child: const Icon(
            Icons.facebook,
            size: 20,
            color: Colors.white,
          ),
        ),
        // 3. Instagram (IG)
        _ShareIconBtn(
          tooltip: 'Salin tautan & Buka Instagram',
          gradient: const LinearGradient(
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _shareToInstagram(context),
          child: const Icon(
            Icons.camera_alt_outlined,
            size: 16,
            color: Colors.white,
          ),
        ),
        // 4. WhatsApp (WA)
        _ShareIconBtn(
          tooltip: 'Bagikan ke WhatsApp',
          background: const Color(0xFF25D366),
          onTap: () => _openUrl('https://api.whatsapp.com/send?text=${Uri.encodeComponent('$title\n$_effectiveUrl')}'),
          child: const Icon(
            Icons.chat,
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ShareIconBtn extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final Color? background;
  final Gradient? gradient;

  const _ShareIconBtn({
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.background,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: gradient == null ? (background ?? AppColors.gray100) : null,
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
