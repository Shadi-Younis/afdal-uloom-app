import 'dart:async';

import 'package:afdal_uloom_tilawat/core/application/account_status_controller.dart';
import 'package:afdal_uloom_tilawat/core/application/sign_out_notice_controller.dart';
import 'package:afdal_uloom_tilawat/core/application/sign_out_reason.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/repository_providers.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_user_repository.dart';

void main() {
  const teacher = AuthSession(uid: 't01', role: UserRole.teacher);

  late FakeAuthService auth;
  late FakeUserRepository users;
  late ProviderContainer container;

  void start({AuthSession? session = teacher}) {
    auth = FakeAuthService(initial: session, sessionAfterSignIn: teacher);
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(users),
      ],
    );
    container.listen(accountStatusControllerProvider, (_, _) {});
    addTearDown(container.dispose);
  }

  // Lets the session and profile streams deliver.
  Future<void> settle() => pumpEventQueue();

  SignOutReason? notice() => container.read(signOutNoticeProvider);

  setUp(() {
    users = FakeUserRepository({
      't01': seedUser('t01', 'الشيخ محمود', UserRole.teacher),
    });
  });

  test('an active account stays signed in', () async {
    start();
    await settle();
    users.put(users.users['t01']!.copyWith(fullName: 'الشيخ محمود علي'));
    await settle();

    expect(auth.signOutCalls, 0);
    expect(notice(), isNull);
  });

  test('its profile is deleted: signed out with the reason', () async {
    start();
    await settle();

    users.remove('t01');
    await settle();

    expect(auth.signOutCalls, 1);
    expect(notice(), SignOutReason.accountInactive);
  });

  test('its account is disabled: signed out with the reason', () async {
    start();
    await settle();

    users.put(users.users['t01']!.copyWith(disabled: true));
    await settle();

    expect(auth.signOutCalls, 1);
    expect(notice(), SignOutReason.accountInactive);
  });

  test('nothing happens before the profile\'s first value', () async {
    users.watchGate = Completer<void>();
    start();
    await settle();
    expect(auth.signOutCalls, 0);

    users.watchGate!.complete();
    await settle();
    expect(auth.signOutCalls, 0);
    expect(notice(), isNull);
  });

  test('signing in normally does not sign out', () async {
    users.watchGate = Completer<void>();
    start(session: null);
    await settle();

    await auth.signIn('t01', 'test1234');
    await settle();
    expect(auth.signOutCalls, 0);

    users.watchGate!.complete();
    await settle();
    expect(auth.signOutCalls, 0);
  });

  test('a profile that cannot be read is no reason to sign out', () async {
    users.watchError = const AppException(AppErrorCode.network);
    start();
    await settle();

    expect(auth.signOutCalls, 0);
    expect(notice(), isNull);
  });

  test('after a normal sign-out, later changes are ignored', () async {
    start();
    await settle();
    await auth.signOut();
    await settle();

    users.remove('t01');
    await settle();

    expect(auth.signOutCalls, 1);
    expect(notice(), isNull);
  });

  test('a second change after the sign-out does not sign out twice', () async {
    start();
    await settle();

    users.put(users.users['t01']!.copyWith(disabled: true));
    users.remove('t01');
    await settle();

    expect(auth.signOutCalls, 1);
  });
}
