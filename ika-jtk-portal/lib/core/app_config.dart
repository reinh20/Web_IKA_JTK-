class AppConfig {
  /// Backend host WITHOUT a trailing `/api`,
  /// e.g. https://api.ikajtk.digitaloasis.xyz
  ///
  /// Baked into the compiled JS at build time via:
  ///   --dart-define=API_BASE_URL=https://api.ikajtk.digitaloasis.xyz
  /// so there is no runtime `.env` fetch (no browser-cache problems).
  static const String serverHost = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  /// API base, always `<host>/api`.
  static String get apiBaseUrl => '$serverHost/api';
}
