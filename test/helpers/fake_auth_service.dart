import 'dart:async';

import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/services/auth_service.dart';

/// An [AuthService] driven by the test.
///
/// - [initialKnown] false: the session stays unknown until [emit] is called.
/// - [signInError]: what signIn throws; otherwise it "succeeds" and emits
///   [sessionAfterSignIn].
/// - [signInGate]: when set, signIn waits for it (to test loading states).
class FakeAuthService implements AuthService {
  FakeAuthService({
    AuthSession? initial,
    this.initialKnown = true,
    this.sessionAfterSignIn,
    this.signInError,
  }) : _current = initial;

  final bool initialKnown;
  AuthSession? sessionAfterSignIn;
  Object? signInError;
  Completer<void>? signInGate;

  final signInCalls = <(String, String)>[];
  int signOutCalls = 0;

  AuthSession? _current;
  final _changes = StreamController<AuthSession?>.broadcast();

  void emit(AuthSession? session) {
    _current = session;
    _changes.add(session);
  }

  @override
  Stream<AuthSession?> sessionChanges() async* {
    if (initialKnown) yield _current;
    yield* _changes.stream;
  }

  @override
  Future<void> signIn(String username, String password) async {
    signInCalls.add((username, password));
    await signInGate?.future;
    if (signInError case final error?) throw error;
    emit(sessionAfterSignIn);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(null);
  }

  /// What changePassword throws; [changePasswordGate] delays it.
  Object? changePasswordError;
  Completer<void>? changePasswordGate;
  final changePasswordCalls = <(String current, String next)>[];

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls.add((currentPassword, newPassword));
    await changePasswordGate?.future;
    if (changePasswordError case final error?) throw error;
  }
}
