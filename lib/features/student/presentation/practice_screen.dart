import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/recording_upload_controller.dart';
import '../../../core/application/student_halaqa_provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/app_snack_bar.dart';
import '../../../core/widgets/common/confirm_dialog.dart';
import '../../../core/widgets/common/content_width.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../../../core/widgets/islamic/app_top_bar.dart';
import '../application/practice_recorder_controller.dart';
import '../application/practice_submit_controller.dart';
import '../application/recorder_phase.dart';
import 'widgets/microphone_denied_card.dart';
import 'widgets/practice_details_card.dart';
import 'widgets/practice_file_card.dart';
import 'widgets/practice_sending_card.dart';
import 'widgets/practice_take_card.dart';
import 'widgets/recorder_card.dart';

/// «سجّل تدريباً»: the surah and ayat, then the recorder (or «اختيار ملف»),
/// listening to the take, and «حفظ» with progress and cancel.
/// Nothing leaves the phone before «حفظ»; once it arrived the page
/// closes and the practice is in the student's list. Leaving while
/// recording, with a take not sent, or while sending asks first.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  static final _upload = recordingUploadControllerProvider(
    PracticeSubmitController.uploadKey,
  );

  Future<bool> _mayLeave(BuildContext context, WidgetRef ref) async {
    final sending = ref.read(_upload).isUploading;
    final unsent = ref.read(practiceRecorderControllerProvider).hasUnsentAudio;
    if (!sending && !unsent) return true;
    return showConfirmDialog(
      context,
      title: AppStrings.leaveRecordingTitle,
      message: sending
          ? AppStrings.leaveSendingMessage
          : AppStrings.leaveRecordingMessage,
      confirmLabel: AppStrings.leave,
      destructive: true,
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    // Looked up now: the page may be rebuilt while sending.
    final back = AppTopBar.backTarget(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = await ref.read(practiceSubmitControllerProvider.notifier).send();
    if (id == null) return;
    showAppSnackBarOn(messenger, AppStrings.practiceSaved);
    back?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Loaded while the student records: «حفظ» needs his halaqa.
    ref.watch(studentHalaqaProvider);
    final sending = ref.watch(_upload.select((s) => s.isUploading));
    final recorder = ref.watch(practiceRecorderControllerProvider);
    final file = ref.watch(practiceSubmitControllerProvider).file;
    final take = recorder.take;
    final Widget audio;
    if (sending) {
      audio = const PracticeSendingCard();
    } else if (file != null) {
      audio = PracticeFileCard(file: file, onSend: () => _send(context, ref));
    } else if (take != null) {
      audio = PracticeTakeCard(
        take: take,
        length: recorder.elapsed,
        limitReached: recorder.limitReached,
        onSend: () => _send(context, ref),
      );
    } else if (recorder.phase == RecorderPhase.permissionDenied) {
      audio = const MicrophoneDeniedCard();
    } else {
      audio = const RecorderCard();
    }
    final canPickFile =
        !sending && file == null && recorder.phase == RecorderPhase.ready;
    return AppPageScaffold(
      title: AppStrings.practiceTitle,
      leaveGuard: () => _mayLeave(context, ref),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PracticeDetailsCard(enabled: !sending),
              const SizedBox(height: AppSizes.spaceM),
              audio,
              if (canPickFile) const _PickFile(),
            ],
          ),
        ),
      ),
    );
  }
}

/// «أو احفظ ملفاً صوتياً من جهازك» and «اختيار ملف».
class _PickFile extends ConsumerWidget {
  const _PickFile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spaceL),
      child: Column(
        children: [
          Text(
            AppStrings.orPickFile,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(practiceSubmitControllerProvider.notifier).pickFile(),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text(AppStrings.pickExistingFile),
          ),
        ],
      ),
    );
  }
}
