import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/repository_providers.dart';
import 'form_submit_state.dart';
import 'input_field.dart';
import 'input_validator.dart';

/// The create-halaqa form: a name and an active teacher.
class CreateHalaqaController extends Notifier<FormSubmitState> {
  @override
  FormSubmitState build() => const FormSubmitState();

  void edited(InputField field) => state = state.edited(field);

  /// The new halaqa's id, or null when validation or the server refused it;
  /// the reason is in the state.
  Future<String?> submit({
    required String name,
    required String? teacherId,
  }) async {
    if (state.submitting) return null;
    final errors = {
      InputField.halaqaName: ?InputValidator.halaqaName(name),
      InputField.teacher: ?InputValidator.choice(teacherId),
    };
    if (errors.isNotEmpty) {
      state = FormSubmitState(fieldErrors: errors);
      return null;
    }

    state = const FormSubmitState(submitting: true);
    try {
      final id = await ref
          .read(halaqaRepositoryProvider)
          .create(name: name.trim(), teacherId: teacherId!);
      if (ref.mounted) state = const FormSubmitState();
      return id;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = FormSubmitState.failed(AppException.wrap(error, stackTrace));
      }
      return null;
    }
  }
}

final createHalaqaControllerProvider =
    NotifierProvider.autoDispose<CreateHalaqaController, FormSubmitState>(
      CreateHalaqaController.new,
    );
