import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/user_role.dart';
import '../../../core/providers/password_generator_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/utils/student_code.dart';
import 'admin_data_providers.dart';
import 'form_submit_state.dart';
import 'input_field.dart';
import 'input_validator.dart';
import 'issued_credentials.dart';

/// The add-student form: validates, calls createUser, and hands back the
/// login details to show once.
class AddStudentController extends Notifier<FormSubmitState> {
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
    required String studentCode,
    required String? halaqaId,
  }) async {
    if (state.submitting) return null;
    final errors = {
      InputField.fullName: ?InputValidator.fullName(fullName),
      InputField.halaqa: ?InputValidator.choice(halaqaId),
      InputField.studentCode: ?InputValidator.studentCode(studentCode),
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
      role: UserRole.student,
    );
    state = const FormSubmitState(submitting: true);
    try {
      await ref
          .read(accountsServiceProvider)
          .createUser(
            username: credentials.username,
            password: password,
            fullName: credentials.fullName,
            role: UserRole.student,
            halaqaId: halaqaId,
            studentCode: InputValidator.normalizeStudentCode(studentCode),
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

final addStudentControllerProvider =
    NotifierProvider.autoDispose<AddStudentController, FormSubmitState>(
      AddStudentController.new,
    );

/// The code the form suggests: one above the highest existing code, or
/// null when S999 is used (the admin then types one).
final suggestedStudentCodeProvider = Provider.autoDispose<AsyncValue<String?>>(
  (ref) => ref
      .watch(adminStudentsProvider)
      .whenData(
        (students) => nextStudentCode(students.map((s) => s.studentCode)),
      ),
);
