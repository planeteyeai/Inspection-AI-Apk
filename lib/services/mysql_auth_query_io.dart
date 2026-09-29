import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mysql_client/mysql_client.dart';

import '../config/database_config.dart';
import 'auth_user.dart';

void _debugAuthDiag(String stage, Object error) {
  if (!kDebugMode) return;
  // Never log password or full credentials.
  debugPrint(
    '[AUTH_DIAG] stage=$stage '
    'type=${error.runtimeType} '
    'message=$error '
    'host=${DatabaseConfig.host} '
    'port=${DatabaseConfig.port} '
    'user=${DatabaseConfig.user} '
    'db=${DatabaseConfig.name} '
    'secure=${DatabaseConfig.secure} '
    'passwordLength=${DatabaseConfig.password.length} '
    'passwordLooksQuoted=${DatabaseConfig.password.startsWith('"') || DatabaseConfig.password.endsWith('"')}',
  );
}

/// Read-only lookup of one active user. Never INSERT/UPDATE/DELETE.
Future<ActiveUserRecord?> findActiveUserImpl(String username) async {
  MySQLConnection? conn;
  var stage = 'createConnection';
  try {
    if (kDebugMode) {
      debugPrint(
        '[AUTH_DIAG] starting auth lookup '
        'host=${DatabaseConfig.host} '
        'port=${DatabaseConfig.port} '
        'user=${DatabaseConfig.user} '
        'db=${DatabaseConfig.name} '
        'secure=${DatabaseConfig.secure} '
        'configured=${DatabaseConfig.isConfigured} '
        'passwordLength=${DatabaseConfig.password.length} '
        'passwordLooksQuoted=${DatabaseConfig.password.startsWith('"') || DatabaseConfig.password.endsWith('"')}',
      );
    }

    conn = await MySQLConnection.createConnection(
      host: DatabaseConfig.host,
      port: DatabaseConfig.port,
      userName: DatabaseConfig.user,
      password: DatabaseConfig.password,
      databaseName: DatabaseConfig.name,
      secure: DatabaseConfig.secure,
    );

    stage = 'connect';
    await conn.connect(timeoutMs: 10000);

    stage = 'execute';
    final result = await conn
        .execute(
          '''
SELECT uid, username, first_name, last_name, user_role, user_status
FROM database_Bms.users
WHERE username = :username
AND user_status = 'Active'
LIMIT 1
''',
          {'username': username},
        )
        .timeout(const Duration(seconds: 12));

    if (result.numOfRows < 1) {
      return null;
    }

    final row = result.rows.first;
    return ActiveUserRecord(
      uid: int.tryParse(row.colByName('uid') ?? '') ?? 0,
      username: row.colByName('username') ?? '',
      firstName: row.colByName('first_name') ?? '',
      lastName: row.colByName('last_name') ?? '',
      userRole: row.colByName('user_role') ?? '',
      userStatus: row.colByName('user_status') ?? '',
    );
  } on AuthConnectionException catch (e) {
    _debugAuthDiag(stage, e);
    rethrow;
  } on TimeoutException catch (e) {
    _debugAuthDiag(stage, e);
    throw const AuthConnectionException();
  } catch (e) {
    _debugAuthDiag(stage, e);
    throw const AuthConnectionException();
  } finally {
    if (conn != null) {
      try {
        await conn.close();
      } catch (_) {
        // Ignore close errors so login can still return a safe result.
      }
    }
  }
}
