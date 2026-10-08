import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/app_user.dart';
import '../../../core/providers/password_generator_provider.dart';
import '../../../core/providers/service_providers.dart';
import 'form_submit_state.dart';
import 'input_field.dart';
import 'input_validator.dart';
import 'issued_credentials.dart';

/// The reset-password dialog of a teacher or student.
class ResetPasswordController extends Notifier<FormSubmitState> {
  @override
  FormSubmitState build() => const FormSubmitState();

  /// A new generated password, for the dialog's initial value and its
  /// "generate again" button.
  String suggestPassword() => ref.read(passwordGeneratorProvider).generate();

  void edited(InputField field) => state = state.edited(field);

  /// The new login details, or null when validation or the server refused
  /// it; the reason is in the state.
  Future<IssuedCredentials?> reset(AppUser user, String password) async {
    if (state.submitting) return null;
    final error = InputValidator.password(password);
    if (error != null) {
      state = FormSubmitState(fieldErrors: {InputField.password: error});
      return null;
    }

    state = const FormSubmitState(submitting: true);
    try {
      await ref
          .read(accountsServiceProvider)
          .resetPassword(uid: user.id, newPassword: password);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = FormSubmitState.failed(AppException.wrap(error, stackTrace));
      }
      return null;
    }
    if (ref.mounted) state = const FormSubmitState();
    return IssuedCredentials(
      fullName: user.fullName,
      username: user.username,
      password: password,
      role: user.role,
    );
  }
}

final resetPasswordControllerProvider =
    NotifierProvider.autoDispose<ResetPasswordController, FormSubmitState>(
      ResetPasswordController.new,
    );
