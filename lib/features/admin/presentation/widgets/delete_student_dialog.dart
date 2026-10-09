import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/admin_data_providers.dart';
import '../../application/delete_user_controller.dart';
import 'form_error_text.dart';

/// Confirms the permanent delete of [student]: the warning, how many
/// recordings go with them, and a field where the admin types the
/// student's code; "حذف نهائي" is enabled only when it matches exactly.
/// Cannot be closed while the call runs. Pops with the number of deleted
/// recordings on success.
class DeleteStudentDialog extends ConsumerStatefulWidget {
  const DeleteStudentDialog({super.key, required this.student});

  final AppUser student;

  /// What the admin must type: the student's code (its username if a
  /// student ever has none).
  String get confirmationCode => student.studentCode ?? student.username;

  @override
  ConsumerState<DeleteStudentDialog> createState() =>
      _DeleteStudentDialogState();
}

class _DeleteStudentDialogState extends ConsumerState<DeleteStudentDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final deleted = await ref
        .read(deleteUserControllerProvider(widget.student.id).notifier)
        .delete();
    if (deleted != null && mounted) Navigator.of(context).pop(deleted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(deleteUserControllerProvider(widget.student.id));
    final recordings = ref
        .watch(studentRecordingsProvider(widget.student.id))
        .value;
    final running = state.isLoading;
    final error = state.error;
    return PopScope(
      canPop: !running,
      child: AlertDialog(
        title: Text(AppStrings.deleteStudentTitle(widget.student.fullName)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.deleteStudentWarning,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              if (recordings != null) ...[
                const SizedBox(height: AppSizes.spaceS),
                Text(
                  AppStrings.recordingsToDelete(
                    toArabicDigits(recordings.length),
                  ),
                  style: theme.textTheme.titleSmall,
                ),
              ],
              const SizedBox(height: AppSizes.spaceM),
              Text(AppStrings.typeCodeToConfirm(widget.confirmationCode)),
              const SizedBox(height: AppSizes.spaceXS),
              TextField(
                controller: _code,
                enabled: !running,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: AppStrings.studentCodeLabel,
                  hintText: widget.confirmationCode,
                  hintTextDirection: TextDirection.ltr,
                ),
                // Only enables the button: purely visual state.
                onChanged: (_) => setState(() {}),
              ),
              if (error != null) ...[
                const SizedBox(height: AppSizes.spaceS),
                FormErrorText(AppException.wrap(error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: running ? null : () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          LoadingButton(
            destructive: true,
            label: AppStrings.deleteStudent,
            loading: running,
            onPressed:
                DeleteUserController.confirms(
                  _code.text,
                  widget.confirmationCode,
                )
                ? _delete
                : null,
          ),
        ],
      ),
    );
  }
}
