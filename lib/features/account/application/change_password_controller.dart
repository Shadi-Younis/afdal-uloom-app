import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/model_limits.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/service_providers.dart';
import 'change_password_state.dart';

/// "تغيير كلمة السر" on the account page: checks the three fields, then
/// AuthService.changePassword. A wrong current password and a weak new one
/// are shown next to their field; anything else is the form's error.
class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  void edited(PasswordInput input) => state = state.edited(input);

  /// Whether the password was changed; otherwise the reason is in the state.
  Future<bool> submit({
    required String current,
    required String next,
    required String confirm,
  }) async {
    if (state.submitting) return false;
    final problems = {
      if (current.isEmpty) PasswordInput.current: PasswordProblem.required,
      PasswordInput.next: ?_lengthProblem(next),
      if (confirm != next) PasswordInput.confirm: PasswordProblem.mismatch,
    };
    if (problems.isNotEmpty) {
      state = ChangePasswordState(problems: problems);
      return false;
    }

    state = const ChangePasswordState(submitting: true);
    try {
      await ref
          .read(authServiceProvider)
          .changePassword(currentPassword: current, newPassword: next);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = ChangePasswordState.failed(
          AppException.wrap(error, stackTrace),
        );
      }
      return false;
    }
    if (ref.mounted) state = const ChangePasswordState();
    return true;
  }

  /// Not trimmed: spaces are part of a password.
  static PasswordProblem? _lengthProblem(String password) {
    if (password.isEmpty) return PasswordProblem.required;
    if (password.length < ModelLimits.passwordMinLength ||
        password.length > ModelLimits.passwordMaxLength) {
      return PasswordProblem.length;
    }
    return null;
  }
}

final changePasswordControllerProvider =
    NotifierProvider.autoDispose<ChangePasswordController, ChangePasswordState>(
      ChangePasswordController.new,
    );
