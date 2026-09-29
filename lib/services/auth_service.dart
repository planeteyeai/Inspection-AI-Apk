import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;

  const AuthResult._({required this.success, this.errorMessage});

  factory AuthResult.ok() => const AuthResult._(success: true);

  factory AuthResult.failed(String message) =>
      AuthResult._(success: false, errorMessage: message);
}

/// User ID login against database_Bms.users. Session is local only.
class AuthService {
  AuthService._();

  static const String authorizedUserId = 'SHRV001';

  /// Separate from StorageService report/GPS keys.
  static const String sessionUserIdKey = 'thermal_ai_auth_user_id';
  static const String sessionUserUidKey = 'thermal_ai_auth_user_uid';

  static Future<bool> hasSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(sessionUserIdKey);
    return saved == authorizedUserId;
  }

  static Future<int?> getCurrentUid() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUid = prefs.getInt(sessionUserUidKey);
    if (cachedUid != null && cachedUid > 0) return cachedUid;

    // Fallback: If session exists with username, query active user to get integer uid
    final savedUsername = prefs.getString(sessionUserIdKey);
    if (savedUsername != null && savedUsername.isNotEmpty) {
      try {
        final record = await DatabaseService.findActiveUser(savedUsername);
        if (record != null && record.uid > 0) {
          await prefs.setInt(sessionUserUidKey, record.uid);
          return record.uid;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<AuthResult> login(String rawUserId) async {
    final userId = rawUserId.trim();
    if (userId.isEmpty) {
      return AuthResult.failed('Please enter your User ID.');
    }

    try {
      final record = await DatabaseService.findActiveUser(userId);
      if (record == null ||
          record.username != authorizedUserId ||
          record.userStatus != 'Active') {
        return AuthResult.failed('Unauthorized User ID.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(sessionUserIdKey, record.username);
      await prefs.setInt(sessionUserUidKey, record.uid);
      return AuthResult.ok();
    } on AuthConnectionException {
      return AuthResult.failed(
        'Unable to connect to authentication service. Please try again.',
      );
    } catch (_) {
      return AuthResult.failed(
        'Unable to connect to authentication service. Please try again.',
      );
    }
  }

  /// Clears only the auth session. Does not touch reports, GPS, or MySQL users.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionUserIdKey);
    await prefs.remove(sessionUserUidKey);
  }
}
