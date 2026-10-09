import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/user_role.dart';
import '../../../core/providers/password_generator_provider.dart';
import '../../../core/providers/service_providers.dart';
import 'form_submit_state.dart';
import 'input_field.dart';
import 'input_validator.dart';
import 'issued_credentials.dart';

/// The add-teacher form: validates, calls createUser, and hands back the
/// login details to show once.
class AddTeacherController extends Notifier<FormSubmitState> {
  @override
  FormSubmitState build() => const FormSubmitState();

  /// A new generated password, for the form's initial value and its
  /// "generate again" button.
  String suggestPassword() => ref.read(passwordGeneratorProvider).generate();

  void edited(InputField field) => state = state.edited(field);

  /// Null when validation or the server refused it; the reason is in the
  /// state.
  Future<IssuedCredentials?> submit({
    required String fullName,
    required String username,
    required String password,
  }) async {
    if (state.submitting) return null;
    final errors = {
      InputField.fullName: ?InputValidator.fullName(fullName),
      InputField.username: ?InputValidator.username(username),
      InputField.password: ?InputValidator.password(password),
    };
    if (errors.isNotEmpty) {
      state = FormSubmitState(fieldErrors: errors);
      return null;
    }

    final credentials = IssuedCredentials(
      fullName: fullName.trim(),
      username: InputValidator.normalizeUsername(username),
      password: password,
      role: UserRole.teacher,
    );
    state = const FormSubmitState(submitting: true);
    try {
      await ref
          .read(accountsServiceProvider)
          .createUser(
            username: credentials.username,
            password: password,
            fullName: credentials.fullName,
            role: UserRole.teacher,
          );
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = FormSubmitState.failed(AppException.wrap(error, stackTrace));
      }
      return null;
    }
    if (ref.mounted) state = const FormSubmitState();
    return credentials;
  }
}

final addTeacherControllerProvider =
    NotifierProvider.autoDispose<AddTeacherController, FormSubmitState>(
      AddTeacherController.new,
    );
