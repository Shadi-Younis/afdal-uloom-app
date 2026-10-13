import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/application/my_students_providers.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording_type.dart';
import '../../../../core/providers/clock_provider.dart';
import '../../../../core/utils/file_size.dart';
import '../../../../core/widgets/common/ayah_range_fields.dart';
import '../../../../core/widgets/common/recording_type_chip.dart';
import '../../../../core/widgets/common/surah_field.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../application/upload_batch_controller.dart';
import '../../application/upload_row.dart';
import '../../application/upload_row_status.dart';
import 'upload_date_field.dart';
import 'upload_row_status_line.dart';
import 'upload_student_field.dart';

/// One file of the upload page: its name and size, the student, surah,
/// ayat and date (editable until it uploads), its type (always «رسمي»),
/// how its upload goes, and the actions that fit: remove, cancel, retry,
/// open the uploaded recording.
class UploadRowCard extends ConsumerWidget {
  const UploadRowCard({
    super.key,
    required this.row,
    required this.students,
    required this.defaultStudentId,
  });

  final UploadRow row;
  final List<StudentInHalaqa> students;

  /// The family key of the page's UploadBatchController.
  final String? defaultStudentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      uploadBatchControllerProvider(defaultStudentId).notifier,
    );
    final key = row.key;
    final editable = row.status.isEditable && row.fileProblem == null;
    final student = UploadStudentField(
      students: students,
      studentId: row.studentId,
      enabled: editable,
      showError: editable && row.studentId == null,
      onChanged: (id) => controller.setStudent(key, id),
    );
    final surah = SurahField(
      surahNumber: row.surahNumber,
      enabled: editable,
      onChanged: (n) => controller.setSurah(key, n),
    );
    final ayat = AyahRangeFields(
      from: row.ayahFrom,
      to: row.ayahTo,
      enabled: editable,
      invalid: row.hasInvalidAyat,
      onFromChanged: (n) => controller.setAyahFrom(key, n),
      onToChanged: (n) => controller.setAyahTo(key, n),
    );
    final date = UploadDateField(
      day: row.recordedAt,
      today: ref.watch(clockProvider)(),
      enabled: editable,
      onChanged: (day) => controller.setRecordedAt(key, day),
    );
    const gap = SizedBox(height: AppSizes.spaceS, width: AppSizes.spaceS);
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= AppSizes.uploadTwoColumnsMinWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(row: row, controller: controller),
              if (row.fileProblem == null) ...[
                gap,
                if (wide) ...[
                  Row(
                    children: [
                      Expanded(child: student),
                      gap,
                      Expanded(child: surah),
                    ],
                  ),
                  gap,
                  Row(
                    children: [
                      Expanded(child: ayat),
                      gap,
                      Expanded(child: date),
                    ],
                  ),
                ] else ...[
                  student,
                  gap,
                  surah,
                  gap,
                  ayat,
                  gap,
                  date,
                ],
              ],
              gap,
              UploadRowStatusLine(row: row),
            ],
          );
        },
      ),
    );
  }
}

/// The file's name and size, «رسمي», and the actions.
class _Header extends StatelessWidget {
  const _Header({required this.row, required this.controller});

  final UploadRow row;
  final UploadBatchController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = row.status;
    return Row(
      children: [
        const Icon(Icons.audio_file_outlined),
        const SizedBox(width: AppSizes.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File names are Latin: keep them left-to-right.
              Text(
                row.file.name,
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                formatFileSize(row.file.sizeBytes),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const RecordingTypeChip(type: RecordingType.official),
        if (status == UploadRowStatus.waiting ||
            status == UploadRowStatus.uploading)
          IconButton(
            tooltip: AppStrings.cancel,
            onPressed: () => controller.cancel(row.key),
            icon: const Icon(Icons.close),
          ),
        if ((status == UploadRowStatus.failed ||
                status == UploadRowStatus.cancelled) &&
            row.canStart)
          IconButton(
            tooltip: AppStrings.retry,
            onPressed: () => controller.retry(row.key),
            icon: const Icon(Icons.refresh),
          ),
        if (status == UploadRowStatus.done && row.recordingId != null)
          IconButton(
            tooltip: AppStrings.openRecording,
            onPressed: () =>
                context.push(AppRoutes.recording(row.recordingId!)),
            icon: const Icon(Icons.open_in_new),
          ),
        if (status.isEditable)
          IconButton(
            tooltip: AppStrings.removeFile,
            onPressed: () => controller.remove(row.key),
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    );
  }
}
