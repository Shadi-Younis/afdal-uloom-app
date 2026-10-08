import '../../../core/models/user_role.dart';

/// Login details just created or reset, shown once to the admin to pass on.
/// The password is never stored or shown again.
class IssuedCredentials {
  const IssuedCredentials({
    required this.fullName,
    required this.username,
    required this.password,
    required this.role,
  });

  final String fullName;
  final String username;
  final String password;
  final UserRole role;

  @override
  bool operator ==(Object other) =>
      other is IssuedCredentials &&
      other.fullName == fullName &&
      other.username == username &&
      other.password == password &&
      other.role == role;

  @override
  int get hashCode => Object.hash(fullName, username, password, role);

  // Leaves the password out: this may end up in logs.
  @override
  String toString() => 'IssuedCredentials($username, $fullName, ${role.value})';
}
