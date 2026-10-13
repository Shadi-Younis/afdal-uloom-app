import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/utils/error_messages.dart';
import '../../application/upload_row.dart';
import '../../application/upload_row_status.dart';

/// How a file's upload goes: why it cannot be uploaded, what is missing,
/// waiting, the progress bar, done, failed (the Arabic reason) or
/// cancelled. In two-file mode also a missing file, why the two cannot go
/// together (e.g. their lengths), and a progress bar for each.
class UploadRowStatusLine extends StatelessWidget {
  const UploadRowStatusLine({super.key, required this.row});

  final UploadRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    final muted = theme.colorScheme.onSurfaceVariant;
    if (row.fileProblem case final problem?) {
      return _Line(text: errorMessageFor(problem), color: error);
    }
    final stemsProblem = row.isStems ? row.stemsProblem : null;
    return switch (row.status) {
      UploadRowStatus.editing when stemsProblem != null => _Line(
        text: errorMessageFor(stemsProblem),
        color: error,
        icon: Icons.error_outline,
      ),
      UploadRowStatus.editing when row.isStems && !row.hasBothStems => _Line(
        text: AppStrings.stemsMissing,
        color: muted,
      ),
      UploadRowStatus.editing when !row.isComplete => _Line(
        text: AppStrings.completeTheRow,
        color: muted,
      ),
      UploadRowStatus.editing => const SizedBox.shrink(),
      UploadRowStatus.waiting => _Line(
        text: AppStrings.uploadWaiting,
        color: muted,
      ),
      UploadRowStatus.uploading => switch (row.stemProgress) {
        final stems? => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Progress(
              value: stems.student,
              text: AppStrings.stemUploading(
                AppStrings.stemStudent,
                _percent(stems.student),
              ),
              color: muted,
            ),
            const SizedBox(height: AppSizes.spaceXS),
            _Progress(
              value: stems.sheikh,
              text: AppStrings.stemUploading(
                AppStrings.stemSheikh,
                _percent(stems.sheikh),
              ),
              color: muted,
            ),
          ],
        ),
        null => _Progress(
          value: row.progress,
          text: AppStrings.uploading(_percent(row.progress)),
          color: muted,
        ),
      },
      UploadRowStatus.done => const _Line(
        text: AppStrings.uploadDone,
        color: AppColors.green,
        icon: Icons.check_circle_outline,
      ),
      UploadRowStatus.failed => _Line(
        text: switch (row.error) {
          final error? => errorMessageFor(error.code),
          null => AppStrings.errorUnknown,
        },
        color: error,
        icon: Icons.error_outline,
      ),
      UploadRowStatus.cancelled => _Line(
        text: AppStrings.uploadCancelled,
        color: muted,
      ),
    };
  }
}

String _percent(double progress) => toArabicDigits((progress * 100).floor());

/// A progress bar with what it is under it.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.value,
    required this.text,
    required this.color,
  });

  final double value;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LinearProgressIndicator(value: value),
      const SizedBox(height: AppSizes.spaceXS),
      _Line(text: text, color: color),
    ],
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon case final icon?) ...[
          Icon(icon, color: color, size: AppSizes.chipIcon),
          const SizedBox(width: AppSizes.spaceXS),
        ],
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
