/// A user's role. [value] is what Firestore (`users/{uid}.role`) and the
/// `role` custom claim store.
enum UserRole {
  admin('admin'),
  teacher('teacher'),
  student('student');

  const UserRole(this.value);

  final String value;

  /// Throws [FormatException] for a string that is not a known role.
  static UserRole fromValue(String value) => values.firstWhere(
    (role) => role.value == value,
    orElse: () => throw FormatException('Unknown user role', value),
  );
}
