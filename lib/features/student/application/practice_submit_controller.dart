import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/recording_upload_controller.dart';
import '../../../core/application/recording_upload_request.dart';
import '../../../core/application/session_providers.dart';
import '../../../core/application/student_halaqa_provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/audio_source.dart';
import '../../../core/models/recording_type.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/utils/audio_file_check.dart';
import 'practice_recorder_controller.dart';
import 'practice_submit_state.dart';

/// The sending side of «سجّل تدريباً»: the surah and ayat, a file picked
/// instead of recording («اختيار ملف»), and «حفظ», which uploads
/// the take (or the file) through RecordingUploadController as a practice
/// of the student's halaqa: `type: practice`, not reviewed, no unread
/// feedback (firestore.rules: isStudentPractice). Progress, cancel and
/// retry are that controller's, under [uploadKey].
class PracticeSubmitController extends Notifier<PracticeSubmitState> {
  /// The key of this page's RecordingUploadController.
  static const uploadKey = 'practice';

  @override
  PracticeSubmitState build() => const PracticeSubmitState();

  void setSurah(int? surahNumber) =>
      state = state.copyWith(surahNumber: () => surahNumber);

  void setAyahFrom(int? ayah) => state = state.copyWith(ayahFrom: () => ayah);

  void setAyahTo(int? ayah) => state = state.copyWith(ayahTo: () => ayah);

  /// Lets the student pick one audio file to send instead of recording.
  Future<void> pickFile() async {
    final files = await ref.read(audioFilePickerProvider).pickAudioFiles();
    if (!ref.mounted || files.isEmpty) return;
    final file = files.first;
    state = state.copyWith(
      file: () => file,
      fileProblem: () => uploadProblemOf(file),
    );
  }

  void clearFile() =>
      state = state.copyWith(file: () => null, fileProblem: () => null);

  /// «حفظ»: the new practice's id once it is saved (his own), or
  /// null when it was refused, failed or was cancelled (the reason is in
  /// this state, or in the upload's). Sends the picked file if there is
  /// one, otherwise the recorder's take.
  Future<String?> send() async {
    if (!state.hasValidAyat) {
      state = state.copyWith(showAyatProblem: true);
      return null;
    }
    final file = state.file;
    final recorder = ref.read(practiceRecorderControllerProvider);
    final take = recorder.take;
    if (file == null && take == null) return null;
    if (file != null && state.fileProblem != null) return null;

    final upload = recordingUploadControllerProvider(uploadKey);
    // Keeps the (autoDispose) upload and halaqa alive while this runs: a
    // provider nobody listens to is paused.
    final subscriptions = [
      ref.listen(upload, (_, _) {}),
      ref.listen(studentHalaqaProvider, (_, _) {}),
    ];
    try {
      final studentId = ref.read(sessionProvider).value?.uid;
      final halaqa = await ref.read(studentHalaqaProvider.future);
      if (!ref.mounted) return null;
      if (studentId == null || halaqa == null) {
        state = state.copyWith(
          error: const AppException(AppErrorCode.permissionDenied),
        );
        return null;
      }
      final AudioSource source;
      final String extension;
      if (file != null) {
        source = await file.open();
        extension = file.extension;
      } else {
        source = take!.source;
        extension = take.extension;
      }
      if (!ref.mounted) return null;
      final id = await ref
          .read(upload.notifier)
          .start(
            RecordingUploadRequest(
              studentId: studentId,
              halaqaId: halaqa.id,
              teacherId: halaqa.teacherId,
              type: RecordingType.practice,
              surahNumber: state.surahNumber!,
              ayahFrom: state.ayahFrom!,
              ayahTo: state.ayahTo!,
              recordedAt: ref.read(clockProvider)(),
              source: source,
              fileExtension: extension,
              // A picked file's length is unknown until it is played.
              durationSec: file == null ? recorder.elapsed.inSeconds : null,
            ),
          );
      if (id != null && ref.mounted) {
        if (file != null) {
          clearFile();
        } else {
          await ref.read(practiceRecorderControllerProvider.notifier).sent();
        }
      }
      return id;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = state.copyWith(error: AppException.wrap(error, stackTrace));
      }
      return null;
    } finally {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    }
  }
}

final practiceSubmitControllerProvider =
    NotifierProvider.autoDispose<PracticeSubmitController, PracticeSubmitState>(
      PracticeSubmitController.new,
    );
