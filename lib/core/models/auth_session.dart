import 'user_role.dart';

/// Who is signed in. [role] comes from the ID token's `role` claim, never
/// from the users document.
class AuthSession {
  const AuthSession({required this.uid, required this.role});

  final String uid;
  final UserRole role;

  @override
  bool operator ==(Object other) =>
      other is AuthSession && other.uid == uid && other.role == role;

  @override
  int get hashCode => Object.hash(uid, role);

  @override
  String toString() => 'AuthSession(uid: $uid, role: ${role.value})';
}
