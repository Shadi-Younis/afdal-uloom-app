import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/my_students_providers.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../application/upload_batch_controller.dart';
import 'upload_drop_area.dart';
import 'upload_row_card.dart';

/// The content of the upload page: how to add files (button, and dropping
/// on the web), a card per file, and «رفع الكل» with how many are done.
class UploadBatchView extends ConsumerWidget {
  const UploadBatchView({
    super.key,
    required this.students,
    required this.defaultStudentId,
  });

  final List<StudentInHalaqa> students;
  final String? defaultStudentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = uploadBatchControllerProvider(defaultStudentId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    Future<void> pick() async {
      final files = await ref.read(audioFilePickerProvider).pickAudioFiles();
      if (files.isNotEmpty) controller.addFiles(files);
    }

    return UploadDropArea(
      onFiles: controller.addFiles,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              children: [
                _Centered(child: _AddFilesCard(onPick: pick)),
                for (final row in state.rows)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.spaceS),
                    child: _Centered(
                      child: UploadRowCard(
                        key: ValueKey(row.key),
                        row: row,
                        students: students,
                        defaultStudentId: defaultStudentId,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (state.rows.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: _Centered(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.uploadedOf(
                            toArabicDigits(state.doneCount),
                            toArabicDigits(state.rows.length),
                          ),
                        ),
                      ),
                      LoadingButton(
                        label: AppStrings.uploadAll,
                        icon: Icons.cloud_upload_outlined,
                        loading: state.running,
                        onPressed: state.canUploadAll
                            ? controller.uploadAll
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// How to add files: the hint, the button, and on the web the drop hint.
class _AddFilesCard extends StatelessWidget {
  const _AddFilesCard({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.uploadHint, style: muted),
          const SizedBox(height: AppSizes.spaceS),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.library_music_outlined),
            label: const Text(AppStrings.pickFiles),
          ),
          if (UploadDropArea.supported) ...[
            const SizedBox(height: AppSizes.spaceXS),
            Text(
              AppStrings.dropHint,
              textAlign: TextAlign.center,
              style: muted,
            ),
          ],
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.uploadMaxWidth),
      child: child,
    ),
  );
}
