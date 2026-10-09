import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/halaqa.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/input_field.dart';
import '../../application/rename_halaqa_controller.dart';
import 'form_error_text.dart';
import 'input_error_text.dart';

/// Renames [halaqa]; pops with true once renamed.
class RenameHalaqaDialog extends ConsumerStatefulWidget {
  const RenameHalaqaDialog({super.key, required this.halaqa});

  final Halaqa halaqa;

  @override
  ConsumerState<RenameHalaqaDialog> createState() => _RenameHalaqaDialogState();
}

class _RenameHalaqaDialogState extends ConsumerState<RenameHalaqaDialog> {
  late final _name = TextEditingController(text: widget.halaqa.name);

  RenameHalaqaController get _controller =>
      ref.read(renameHalaqaControllerProvider.notifier);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final renamed = await _controller.rename(widget.halaqa.id, _name.text);
    if (renamed && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(renameHalaqaControllerProvider);
    return PopScope(
      canPop: !state.submitting,
      child: AlertDialog(
        title: const Text(AppStrings.renameHalaqaTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              enabled: !state.submitting,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _controller.edited(InputField.halaqaName),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: AppStrings.halaqaNameLabel,
                errorText: inputErrorText(state, InputField.halaqaName),
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: AppSizes.spaceS),
              FormErrorText(state.error),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: state.submitting
                ? null
                : () => Navigator.of(context).pop(false),
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
