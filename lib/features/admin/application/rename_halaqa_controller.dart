import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/repository_providers.dart';
import 'form_submit_state.dart';
import 'input_field.dart';
import 'input_validator.dart';

/// The rename dialog of a halaqa.
class RenameHalaqaController extends Notifier<FormSubmitState> {
  @override
  FormSubmitState build() => const FormSubmitState();

  void edited(InputField field) => state = state.edited(field);

  /// Whether it was renamed; otherwise the reason is in the state.
  Future<bool> rename(String halaqaId, String name) async {
    if (state.submitting) return false;
    final error = InputValidator.halaqaName(name);
    if (error != null) {
      state = FormSubmitState(fieldErrors: {InputField.halaqaName: error});
      return false;
    }

    state = const FormSubmitState(submitting: true);
    try {
      await ref.read(halaqaRepositoryProvider).rename(halaqaId, name.trim());
      if (ref.mounted) state = const FormSubmitState();
      return true;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = FormSubmitState.failed(AppException.wrap(error, stackTrace));
      }
      return false;
    }
  }
}

final renameHalaqaControllerProvider =
    NotifierProvider.autoDispose<RenameHalaqaController, FormSubmitState>(
      RenameHalaqaController.new,
    );
