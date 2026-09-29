/// Standalone MySQL auth diagnostics. Does not print passwords.
///
/// Run (PowerShell — do not put quotes around the password value):
/// dart run tool/mysql_auth_diag.dart --define=DB_HOST=... --define=DB_PORT=21737 --define=DB_USER=root --define=DB_PASSWORD=... --define=DB_NAME=database_Bms --define=DB_SECURE=false
library;

import 'dart:io';

import 'package:mysql_client/mysql_client.dart';

const host = String.fromEnvironment('DB_HOST');
const port = int.fromEnvironment('DB_PORT', defaultValue: 3306);
const user = String.fromEnvironment('DB_USER');
const password = String.fromEnvironment('DB_PASSWORD');
const name = String.fromEnvironment('DB_NAME', defaultValue: 'database_Bms');
const secure = bool.fromEnvironment('DB_SECURE', defaultValue: false);

Future<void> main() async {
  stdout.writeln(
    'DIAG config host=$host port=$port user=$user db=$name '
    'secure=$secure passwordLength=${password.length} '
    'passwordLooksQuoted=${password.startsWith('"') || password.endsWith('"')}',
  );

  MySQLConnection? conn;
  var stage = 'createConnection';
  try {
    conn = await MySQLConnection.createConnection(
      host: host,
      port: port,
      userName: user,
      password: password,
      databaseName: name,
      secure: secure,
    );
    stage = 'connect';
    await conn.connect(timeoutMs: 15000);
    stage = 'execute';
    final result = await conn.execute(
      '''
SELECT uid, username, first_name, last_name, user_role, user_status
FROM database_Bms.users
WHERE username = :username
AND user_status = 'Active'
LIMIT 1
''',
      {'username': 'SHRV001'},
    );
    stdout.writeln('DIAG success stage=$stage rows=${result.numOfRows}');
    if (result.numOfRows > 0) {
      final row = result.rows.first;
      stdout.writeln(
        'DIAG user username=${row.colByName('username')} '
        'status=${row.colByName('user_status')} '
        'role=${row.colByName('user_role')}',
      );
    }
  } catch (e) {
    stderr.writeln('DIAG FAIL stage=$stage type=${e.runtimeType} message=$e');
    exitCode = 1;
  } finally {
    await conn?.close();
  }
}
