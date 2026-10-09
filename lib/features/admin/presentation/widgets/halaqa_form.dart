import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../application/create_halaqa_controller.dart';
import '../../application/input_field.dart';
import 'form_submit_section.dart';
import 'input_error_text.dart';
import 'picker_field.dart';

/// Name and teacher of a new halaqa. [teachers] are the active ones.
class HalaqaForm extends ConsumerStatefulWidget {
  const HalaqaForm({
    super.key,
    required this.teachers,
    required this.onCreated,
  });

  final List<AppUser> teachers;

  /// Called with the new halaqa's id.
  final ValueChanged<String> onCreated;

  @override
  ConsumerState<HalaqaForm> createState() => _HalaqaFormState();
}

class _HalaqaFormState extends ConsumerState<HalaqaForm> {
  final _name = TextEditingController();
  // The chosen teacher is input, like the text field: local state.
  String? _teacherId;

  CreateHalaqaController get _controller =>
      ref.read(createHalaqaControllerProvider.notifier);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final id = await _controller.submit(
      name: _name.text,
      teacherId: _teacherId,
    );
    if (id != null && mounted) widget.onCreated(id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createHalaqaControllerProvider);
    final enabled = !state.submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          enabled: enabled,
          onChanged: (_) => _controller.edited(InputField.halaqaName),
          decoration: InputDecoration(
            labelText: AppStrings.halaqaNameLabel,
            errorText: inputErrorText(state, InputField.halaqaName),
          ),
        ),
        const SizedBox(height: AppSizes.spaceS),
        PickerField(
          label: AppStrings.teacherLabel,
          value: _teacherId,
          choices: [
            for (final t in widget.teachers) (id: t.id, label: t.fullName),
          ],
          enabled: enabled,
          errorText: inputErrorText(state, InputField.teacher),
          onChanged: (id) {
            setState(() => _teacherId = id);
            _controller.edited(InputField.teacher);
          },
        ),
        FormSubmitSection(
          label: AppStrings.create,
          icon: Icons.group_add_outlined,
          state: state,
          onPressed: _submit,
        ),
      ],
    );
  }
}
