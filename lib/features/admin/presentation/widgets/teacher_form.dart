import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/add_teacher_controller.dart';
import '../../application/input_field.dart';
import '../../application/issued_credentials.dart';
import 'form_submit_section.dart';
import 'input_error_text.dart';
import 'password_input.dart';
import 'username_input.dart';

/// Name, username and (generated, editable) password of a new teacher.
class TeacherForm extends ConsumerStatefulWidget {
  const TeacherForm({super.key, required this.onCreated});

  final ValueChanged<IssuedCredentials> onCreated;

  @override
  ConsumerState<TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends ConsumerState<TeacherForm> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  AddTeacherController get _controller =>
      ref.read(addTeacherControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _password.text = _controller.suggestPassword();
  }

  @override
  void dispose() {
    for (final c in [_name, _username, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final credentials = await _controller.submit(
      fullName: _name.text,
      username: _username.text,
      password: _password.text,
    );
    if (credentials != null && mounted) widget.onCreated(credentials);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addTeacherControllerProvider);
    final enabled = !state.submitting;
    return Column(
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
        const SizedBox(height: AppSizes.spaceS),
        UsernameInput(
          controller: _username,
          enabled: enabled,
          errorText: inputErrorText(state, InputField.username),
          onChanged: () => _controller.edited(InputField.username),
        ),
        const SizedBox(height: AppSizes.spaceS),
        PasswordInput(
          controller: _password,
          enabled: enabled,
          errorText: inputErrorText(state, InputField.password),
          onRegenerate: () {
            _password.text = _controller.suggestPassword();
            _controller.edited(InputField.password);
          },
          onChanged: () => _controller.edited(InputField.password),
        ),
        FormSubmitSection(
          label: AppStrings.add,
          icon: Icons.person_add_outlined,
          state: state,
          onPressed: _submit,
        ),
      ],
    );
  }
}
