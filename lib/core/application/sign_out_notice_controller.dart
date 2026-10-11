import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sign_out_reason.dart';

/// The reason for the last sign-out the app did by itself, until the user
/// tries to sign in again. Null after a normal sign-out.
class SignOutNoticeController extends Notifier<SignOutReason?> {
  @override
  SignOutReason? build() => null;

  void show(SignOutReason reason) => state = reason;

  void clear() => state = null;
}

final signOutNoticeProvider =
    NotifierProvider<SignOutNoticeController, SignOutReason?>(
      SignOutNoticeController.new,
    );
