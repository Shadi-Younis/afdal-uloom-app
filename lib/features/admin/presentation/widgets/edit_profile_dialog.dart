import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/edit_profile_controller.dart';
import '../../application/input_field.dart';
import 'form_error_text.dart';
import 'input_error_text.dart';
import 'username_input.dart';

/// Edits [user]'s name and username, and a student's code. Pops with true
/// once saved. Cannot be closed while the call runs.
class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _username = TextEditingController(text: widget.user.username);
  late final _code = TextEditingController(text: widget.user.studentCode);

  bool get _isStudent => widget.user.role == UserRole.student;

  EditProfileController get _controller =>
      ref.read(editProfileControllerProvider.notifier);

  @override
  void dispose() {
    for (final c in [_name, _username, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final saved = await _controller.save(
      widget.user,
      fullName: _name.text,
      username: _username.text,
      studentCode: _isStudent ? _code.text : null,
    );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileControllerProvider);
    final enabled = !state.submitting;
    const gap = SizedBox(height: AppSizes.spaceS);
    return PopScope(
      canPop: enabled,
      child: AlertDialog(
        title: Text(AppStrings.editProfileTitle(widget.user.fullName)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                enabled: enabled,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _controller.edited(InputField.fullName),
                decoration: InputDecoration(
                  labelText: AppStrings.fullNameLabel,
                  errorText: inputErrorText(state, InputField.fullName),
                ),
              ),
              gap,
              UsernameInput(
                controller: _username,
                enabled: enabled,
                errorText: inputErrorText(state, InputField.username),
                onChanged: () => _controller.edited(InputField.username),
              ),
              const SizedBox(height: AppSizes.spaceXS),
              Text(
                AppStrings.usernameChangeHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_isStudent) ...[
                gap,
                TextField(
                  controller: _code,
                  enabled: enabled,
                  textDirection: TextDirection.ltr,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  onChanged: (_) => _controller.edited(InputField.studentCode),
                  decoration: InputDecoration(
                    labelText: AppStrings.studentCodeLabel,
                    errorText: inputErrorText(state, InputField.studentCode),
                  ),
                ),
              ],
              if (state.error != null) ...[gap, FormErrorText(state.error)],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: enabled ? () => Navigator.of(context).pop(false) : null,
            child: const Text(AppStrings.cancel),
          ),
          LoadingButton(
            label: AppStrings.save,
            loading: state.submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
