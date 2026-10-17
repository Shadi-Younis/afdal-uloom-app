import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/ayat_problem.dart';
import 'ayat_editor_state.dart';

/// «تعديل السورة والآيات» of an official recording (its teacher, admins):
/// fill in, change or clear the surah and ayat the upload left out. The
/// same choices as the upload page are allowed (ayatProblemOf).
class AyatEditorController extends Notifier<AyatEditorState> {
  @override
  AyatEditorState build() => const AyatEditorState();

  /// The user changed a field: the refusal and the last error go.
  void edited() => state = AyatEditorState(submitting: state.submitting);

  /// Saves [surah], [from] and [to] on recording [recordingId]. Whether it
  /// was saved; otherwise the reason is in the state.
  Future<bool> save({
    required String recordingId,
    required int? surah,
    required int? from,
    required int? to,
  }) async {
    if (state.submitting) return false;
    if (ayatProblemOf(surah, from, to) case final problem?) {
      state = AyatEditorState(problem: problem);
      return false;
    }
    state = const AyatEditorState(submitting: true);
    try {
      await ref
          .read(recordingRepositoryProvider)
          .setSurahAndAyat(
            recordingId,
            surahNumber: surah,
            ayahFrom: from,
            ayahTo: to,
          );
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AyatEditorState(error: AppException.wrap(error, stackTrace));
      }
      return false;
    }
    if (ref.mounted) state = const AyatEditorState();
    return true;
  }
}

final ayatEditorControllerProvider =
    NotifierProvider.autoDispose<AyatEditorController, AyatEditorState>(
      AyatEditorController.new,
    );
