import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import 'session_providers.dart';
import 'sign_out_notice_controller.dart';
import 'sign_out_reason.dart';

/// Signs the user out at once when their account stops being usable while
/// they are signed in: their `users/{uid}` document is deleted, or its
/// `disabled` turns true. The ID token alone would keep working for up to
/// an hour. The login screen then says why ([SignOutReason.accountInactive]).
///
/// Only values of the document stream count: nothing happens while the
/// first one is still on its way (e.g. right after signing in), and a read
/// error is not taken as proof that the account is gone. The stream never
/// reports "missing" from the offline cache (UserRepository.watchUser).
///
/// Kept alive by the app widget for the whole session.
class AccountStatusController extends Notifier<void> {
  @override
  void build() {
    final uid = ref.watch(sessionProvider.select((s) => s.value?.uid));
    if (uid == null) return;
    var ended = false;
    final subscription = ref
        .watch(userRepositoryProvider)
        .watchUser(uid)
        .listen(
          (user) {
            if (ended || _isActive(user)) return;
            ended = true;
            unawaited(_signOut());
          },
          onError: (Object _) {},
        );
    ref.onDispose(subscription.cancel);
  }

  static bool _isActive(AppUser? user) => user != null && !user.disabled;

  Future<void> _signOut() async {
    ref.read(signOutNoticeProvider.notifier).show(SignOutReason.accountInactive);
    try {
      await ref.read(authServiceProvider).signOut();
    } on Object {
      // AuthService.signOut does not throw for a signed-in user; if it ever
      // did, there is nothing better to do than stay on the current page.
    }
  }
}

final accountStatusControllerProvider =
    NotifierProvider<AccountStatusController, void>(
      AccountStatusController.new,
    );
