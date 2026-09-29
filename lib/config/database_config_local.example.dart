/// Copy this file to: database_config_local.dart
/// Then replace YOUR_DB_PASSWORD with your real MySQL password.
///
/// database_config_local.dart is gitignored and is used when you run
/// plain `flutter run` without --dart-define flags.
class DatabaseConfigLocal {
  static const String dbHost = 'caboose.proxy.rlwy.net';
  static const int dbPort = 21737;
  static const String dbUser = 'root';
  static const String dbPassword = 'YOUR_DB_PASSWORD';
  static const String dbName = 'database_Bms';
  static const bool dbSecure = true;
}
