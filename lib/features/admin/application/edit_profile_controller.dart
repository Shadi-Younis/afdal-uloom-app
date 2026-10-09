import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/user_role.dart';
import '../../../core/providers/service_providers.dart';
import 'form_submit_state.dart';
import 'input_field.dart';
import 'input_validator.dart';

/// The edit dialog of an account: name and username for everyone, the code
/// for a student. Sends only what changed, through updateUserProfile.
class EditProfileController extends Notifier<FormSubmitState> {
  @override
  FormSubmitState build() => const FormSubmitState();

  void edited(InputField field) => state = state.edited(field);

  /// Whether the profile is saved (also true when nothing changed: there
  /// is nothing to send); otherwise the reason is in the state.
  /// [studentCode] is ignored for anyone but a student.
  Future<bool> save(
    AppUser user, {
    required String fullName,
    required String username,
    String? studentCode,
  }) async {
    if (state.submitting) return false;
    final isStudent = user.role == UserRole.student;
    final errors = {
      InputField.fullName: ?InputValidator.fullName(fullName),
      InputField.username: ?InputValidator.username(username),
      if (isStudent && studentCode != null)
        InputField.studentCode: ?InputValidator.studentCode(studentCode),
    };
    if (errors.isNotEmpty) {
      state = FormSubmitState(fieldErrors: errors);
      return false;
    }

    final name = fullName.trim();
    final login = InputValidator.normalizeUsername(username);
    final code = isStudent && studentCode != null
        ? InputValidator.normalizeStudentCode(studentCode)
        : null;
    final changedName = name == user.fullName ? null : name;
    final changedLogin = login == user.username ? null : login;
    final changedCode = code == null || code == user.studentCode ? null : code;
    if (changedName == null && changedLogin == null && changedCode == null) {
      return true;
    }

    state = const FormSubmitState(submitting: true);
    try {
      await ref
          .read(accountsServiceProvider)
          .updateUserProfile(
            uid: user.id,
            fullName: changedName,
            username: changedLogin,
            studentCode: changedCode,
          );
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = FormSubmitState.failed(AppException.wrap(error, stackTrace));
      }
      return false;
    }
    if (ref.mounted) state = const FormSubmitState();
    return true;
  }
}

final editProfileControllerProvider =
    NotifierProvider.autoDispose<EditProfileController, FormSubmitState>(
      EditProfileController.new,
    );
