import 'auth_user.dart';

/// Used on platforms without dart:io sockets (Flutter web).
/// Browsers cannot open a raw MySQL TCP connection.
Future<ActiveUserRecord?> findActiveUserImpl(String username) async {
  if (username.isEmpty) {
    return null;
  }
  throw const AuthConnectionException();
}
