import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFFDBEAFE);

  static const accent = Color(0xFFF97316);
  static const accentDark = Color(0xFFEA580C);
  static const accentLight = Color(0xFFFFEDD5);

  static const navy = Color(0xFF1E2A4D);
  static const navyLight = Color(0xFF2A3A6B);

  static const peach = Color(0xFFFFF1E5);

  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFD1FAE5);
  static const danger = Color(0xFFDC2626);

  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double section = 96;
}

class AppRadius {
  AppRadius._();
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double pill = 999;
}

class AppBreakpoints {
  AppBreakpoints._();
  static const double mobile = 640;
  static const double tablet = 1024;
  static const double desktop = 1280;
}

extension StringHtmlExtension on String {
  String get stripHtml {
    return replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
