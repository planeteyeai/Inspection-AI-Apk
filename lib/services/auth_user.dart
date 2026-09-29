class AuthConnectionException implements Exception {
  const AuthConnectionException();
}

class ActiveUserRecord {
  final int uid;
  final String username;
  final String firstName;
  final String lastName;
  final String userRole;
  final String userStatus;

  const ActiveUserRecord({
    required this.uid,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.userRole,
    required this.userStatus,
  });
}
