import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/halaqa.dart';
import '../../../../core/utils/student_code.dart';
import '../../application/add_student_controller.dart';
import '../../application/input_field.dart';
import '../../application/issued_credentials.dart';
import 'form_submit_section.dart';
import 'input_error_text.dart';
import 'password_input.dart';
import 'picker_field.dart';
import 'username_input.dart';

/// Name, halaqa, code, username and password of a new student. The code
/// and username come prefilled, the password generated; all editable. The
/// username follows the code until the admin edits it.
class StudentForm extends ConsumerStatefulWidget {
  const StudentForm({
    super.key,
    required this.halaqat,
    required this.suggestedCode,
    required this.initialHalaqaId,
    required this.onCreated,
  });

  final List<Halaqa> halaqat;
  final String? suggestedCode;
  final String? initialHalaqaId;
  final ValueChanged<IssuedCredentials> onCreated;

  @override
  ConsumerState<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends ConsumerState<StudentForm> {
  final _name = TextEditingController();
  late final _code = TextEditingController(text: widget.suggestedCode ?? '');
  late final _username = TextEditingController(
    text: usernameForStudentCode(widget.suggestedCode ?? ''),
  );
  final _password = TextEditingController();
  // The chosen halaqa is input, like the text fields: local state.
  late String? _halaqaId =
      widget.halaqat.any((h) => h.id == widget.initialHalaqaId)
      ? widget.initialHalaqaId
      : null;
  bool _usernameEdited = false;

  AddStudentController get _controller =>
      ref.read(addStudentControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _password.text = _controller.suggestPassword();
  }

  @override
  void dispose() {
    for (final c in [_name, _code, _username, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _codeChanged(String code) {
    _controller.edited(InputField.studentCode);
    if (!_usernameEdited) _username.text = usernameForStudentCode(code);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final credentials = await _controller.submit(
      fullName: _name.text,
      username: _username.text,
      password: _password.text,
      studentCode: _code.text,
      halaqaId: _halaqaId,
    );
    if (credentials != null && mounted) widget.onCreated(credentials);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addStudentControllerProvider);
    final enabled = !state.submitting;
    const gap = SizedBox(height: AppSizes.spaceS);
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
        gap,
        PickerField(
          label: AppStrings.halaqaLabel,
          value: _halaqaId,
          choices: [for (final h in widget.halaqat) (id: h.id, label: h.name)],
          enabled: enabled,
          errorText: inputErrorText(state, InputField.halaqa),
          onChanged: (id) {
            setState(() => _halaqaId = id);
            _controller.edited(InputField.halaqa);
          },
        ),
        gap,
        TextField(
          controller: _code,
          enabled: enabled,
          textDirection: TextDirection.ltr,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          onChanged: _codeChanged,
          decoration: InputDecoration(
            labelText: AppStrings.studentCodeLabel,
            helperText: widget.suggestedCode == null
                ? AppStrings.noFreeStudentCode
                : null,
            errorText: inputErrorText(state, InputField.studentCode),
          ),
        ),
        gap,
        UsernameInput(
          controller: _username,
          enabled: enabled,
          errorText: inputErrorText(state, InputField.username),
          onChanged: () {
            _usernameEdited = true;
            _controller.edited(InputField.username);
          },
        ),
        gap,
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
          icon: Icons.person_add_alt_1_outlined,
          state: state,
          onPressed: _submit,
        ),
      ],
    );
  }
}
