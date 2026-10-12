import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/recording_upload_controller.dart';
import '../../../../core/application/recording_upload_status.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/error_messages.dart';
import '../../application/practice_submit_controller.dart';
import 'practice_notice.dart';

/// Why the last «إرسال للشيخ» did not arrive: refused before it started,
/// failed (the Arabic reason) or cancelled. Nothing otherwise. Sending
/// again is the retry.
class PracticeSendFailure extends ConsumerWidget {
  const PracticeSendFailure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final upload = ref.watch(
      recordingUploadControllerProvider(PracticeSubmitController.uploadKey),
    );
    final failure =
        ref.watch(practiceSubmitControllerProvider).error ??
        switch (upload.status) {
          RecordingUploadStatus.failed =>
            upload.error ?? const AppException(AppErrorCode.unknown),
          _ => null,
        };
    final Widget notice;
    if (failure != null) {
      notice = PracticeNotice(
        text: errorMessageOf(failure),
        color: theme.colorScheme.error,
        icon: Icons.error_outline,
      );
    } else if (upload.status == RecordingUploadStatus.cancelled) {
      notice = PracticeNotice(
        text: AppStrings.uploadCancelled,
        color: theme.colorScheme.onSurfaceVariant,
        icon: Icons.info_outline,
      );
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceS),
      child: notice,
    );
  }
}
