import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/utils/ayat_problem.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/common/ayah_range_fields.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../../../core/widgets/common/surah_field.dart';
import '../../application/ayat_editor_controller.dart';

/// Opens «تعديل السورة والآيات» for [recording]. Resolves to true once
/// saved.
Future<bool> showAyatDialog(BuildContext context, Recording recording) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AyatDialog(recording: recording),
    ) ??
    false;

/// The dialog of [showAyatDialog]: the surah and the ayat, with the same
/// fields and checks as the upload page; all may stay empty.
class AyatDialog extends ConsumerStatefulWidget {
  const AyatDialog({super.key, required this.recording});

  final Recording recording;

  @override
  ConsumerState<AyatDialog> createState() => _AyatDialogState();
}

class _AyatDialogState extends ConsumerState<AyatDialog> {
  // Purely the dialog's own input until it is saved.
  late int? _surah = widget.recording.surahNumber;
  late int? _from = widget.recording.ayahFrom;
  late int? _to = widget.recording.ayahTo;

  AyatEditorController get _controller =>
      ref.read(ayatEditorControllerProvider.notifier);

  void _set(VoidCallback change) {
    setState(change);
    _controller.edited();
  }

  Future<void> _submit() async {
    final saved = await _controller.save(
      recordingId: widget.recording.id,
      surah: _surah,
      from: _from,
      to: _to,
    );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ayatEditorControllerProvider);
    final theme = Theme.of(context);
    final problem = ayatProblemOf(_surah, _from, _to) ?? state.problem;
    return PopScope(
      canPop: !state.submitting,
      child: AlertDialog(
        title: const Text(AppStrings.editAyat),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.ayatOptional,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSizes.spaceS),
              SurahField(
                surahNumber: _surah,
                enabled: !state.submitting,
                onChanged: (n) => _set(() => _surah = n),
              ),
              const SizedBox(height: AppSizes.spaceS),
              AyahRangeFields(
                from: _from,
                to: _to,
                enabled: !state.submitting,
                error: problem?.message,
                onFromChanged: (n) => _set(() => _from = n),
                onToChanged: (n) => _set(() => _to = n),
              ),
              if (state.error case final error?) ...[
                const SizedBox(height: AppSizes.spaceS),
                Text(
                  errorMessageFor(error.code),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
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
