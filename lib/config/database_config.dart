import 'database_config_local.dart' as local;

/// Local MySQL configuration for instructor-required direct Flutter → MySQL login.
///
/// THIS IS NOT SUITABLE FOR A PUBLIC PRODUCTION APPLICATION.
///
/// Values are resolved in this order:
/// 1. --dart-define=DB_* flags (if provided)
/// 2. lib/config/database_config_local.dart (for plain `flutter run`)
///
/// Fill the password once in database_config_local.dart (gitignored),
/// OR pass all values with --dart-define.
///
/// Do not put credentials in LoginScreen, AuthService, or any UI file.
class DatabaseConfig {
  DatabaseConfig._();

  static const String _hostEnv = String.fromEnvironment('DB_HOST');
  static const int _portEnv = int.fromEnvironment('DB_PORT', defaultValue: -1);
  static const String _userEnv = String.fromEnvironment('DB_USER');
  static const String _passwordEnv = String.fromEnvironment('DB_PASSWORD');
  static const String _nameEnv = String.fromEnvironment('DB_NAME');
  static const String _secureEnv = String.fromEnvironment('DB_SECURE');

  static String get host =>
      _hostEnv.isNotEmpty ? _hostEnv : local.DatabaseConfigLocal.dbHost;

  static int get port =>
      _portEnv > 0 ? _portEnv : local.DatabaseConfigLocal.dbPort;

  static String get user =>
      _userEnv.isNotEmpty ? _userEnv : local.DatabaseConfigLocal.dbUser;

  static String get password => _passwordEnv.isNotEmpty
      ? _passwordEnv
      : local.DatabaseConfigLocal.dbPassword;

  static String get name =>
      _nameEnv.isNotEmpty ? _nameEnv : local.DatabaseConfigLocal.dbName;

  static bool get secure {
    if (_secureEnv == 'true') return true;
    if (_secureEnv == 'false') return false;
    return local.DatabaseConfigLocal.dbSecure;
  }

  static bool get isConfigured {
    return host.isNotEmpty &&
        host != 'YOUR_DB_HOST' &&
        user.isNotEmpty &&
        user != 'YOUR_DB_USER' &&
        password.isNotEmpty &&
        password != 'YOUR_DB_PASSWORD' &&
        name == 'database_Bms';
  }
}
