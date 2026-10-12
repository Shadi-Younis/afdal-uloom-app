import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/my_students_providers.dart';
import '../../../core/application/recording_upload_controller.dart';
import '../../../core/application/recording_upload_request.dart';
import '../../../core/application/recording_upload_status.dart';
import '../../../core/constants/audio_formats.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/picked_audio_file.dart';
import '../../../core/models/recording_type.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/utils/recording_file_name.dart';
import 'upload_batch_state.dart';
import 'upload_row.dart';
import 'upload_row_status.dart';

/// The upload page of the teacher (and admin): many studio files, each
/// with its student, surah, ayat and date, uploaded one after another
/// with progress, cancel and retry. Each upload is the agreed flow of
/// RecordingUploadController (new id, document, file; the document is
/// deleted again when the file fails).
///
/// [defaultStudentId] (the student page the page was opened from) fills in
/// the student of files whose name names none.
class UploadBatchController extends Notifier<UploadBatchState> {
  UploadBatchController(this.defaultStudentId);

  final String? defaultStudentId;
  var _nextKey = 0;

  @override
  UploadBatchState build() => const UploadBatchState();

  /// Adds a row per file, with what its name says (parseRecordingFileName)
  /// filled in. A code that is not one of the uploader's students leaves
  /// the student empty; a file that cannot be uploaded (type, size) gets
  /// a row that shows why.
  void addFiles(List<PickedAudioFile> files) {
    final students = ref.read(myStudentsProvider).value ?? const [];
    final today = ref.read(clockProvider)();
    final added = [
      for (final file in files)
        () {
          final parsed = parseRecordingFileName(file.name);
          final code = parsed.studentCode;
          final byCode = code == null
              ? null
              : students
                    .where((s) => s.student.studentCode == code)
                    .firstOrNull;
          final fallback = students
              .where((s) => s.student.id == defaultStudentId)
              .firstOrNull;
          return UploadRow(
            key: 'upload-${_nextKey++}',
            file: file,
            fileProblem: _fileProblem(file),
            studentId: code == null ? fallback?.student.id : byCode?.student.id,
            surahNumber: parsed.surahNumber,
            ayahFrom: parsed.ayahFrom,
            ayahTo: parsed.ayahTo,
            recordedAt: parsed.recordedAt ?? today,
          );
        }(),
    ];
    state = UploadBatchState(
      rows: [...state.rows, ...added],
      running: state.running,
    );
  }

  void setStudent(String key, String? studentId) =>
      _edit(key, (row) => row.copyWith(studentId: () => studentId));

  /// The ayat are kept; if they are not in the new surah, the row says so
  /// and cannot start (UploadRow.hasInvalidAyat).
  void setSurah(String key, int? surahNumber) =>
      _edit(key, (row) => row.copyWith(surahNumber: () => surahNumber));

  void setAyahFrom(String key, int? ayah) =>
      _edit(key, (row) => row.copyWith(ayahFrom: () => ayah));

  void setAyahTo(String key, int? ayah) =>
      _edit(key, (row) => row.copyWith(ayahTo: () => ayah));

  void setRecordedAt(String key, DateTime day) =>
      _edit(key, (row) => row.copyWith(recordedAt: day));

  void remove(String key) {
    if (state.row(key)?.status.isEditable != true) return;
    state = UploadBatchState(
      rows: [...state.rows.where((row) => row.key != key)],
      running: state.running,
    );
  }

  /// Uploads every complete row that is not uploaded yet, one after
  /// another. Rows with missing fields are left as they are.
  Future<void> uploadAll() async {
    if (state.running) return;
    for (final row in state.rows.where((row) => row.canStart)) {
      _update(row.key, (row) => row.copyWith(status: UploadRowStatus.waiting));
    }
    await _drain();
  }

  /// Uploads [key] again after a failure or a cancel (after the others, if
  /// «رفع الكل» is running).
  Future<void> retry(String key) async {
    if (state.row(key)?.canStart != true) return;
    _update(key, (row) => row.copyWith(status: UploadRowStatus.waiting));
    if (!state.running) await _drain();
  }

  /// Stops the upload of [key], or takes it out of the queue.
  Future<void> cancel(String key) async {
    switch (state.row(key)?.status) {
      case UploadRowStatus.waiting:
        _update(key, (row) => row.copyWith(status: UploadRowStatus.cancelled));
      case UploadRowStatus.uploading:
        await ref
            .read(recordingUploadControllerProvider(key).notifier)
            .cancel();
      default:
        break;
    }
  }

  /// Uploads the waiting rows in order until none is left.
  Future<void> _drain() async {
    _setRunning(true);
    try {
      while (ref.mounted) {
        final next = state.rows
            .where((row) => row.status == UploadRowStatus.waiting)
            .firstOrNull;
        if (next == null) break;
        await _upload(next);
      }
    } finally {
      if (ref.mounted) _setRunning(false);
    }
  }

  Future<void> _upload(UploadRow row) async {
    final key = row.key;
    _update(
      key,
      (row) => row.copyWith(
        status: UploadRowStatus.uploading,
        progress: 0,
        error: () => null,
      ),
    );
    final student = (ref.read(myStudentsProvider).value ?? const [])
        .where((s) => s.student.id == row.studentId)
        .firstOrNull;
    if (student == null) {
      return _fail(key, const AppException(AppErrorCode.permissionDenied));
    }

    final provider = recordingUploadControllerProvider(key);
    // Listening keeps the (autoDispose) upload alive and reports progress.
    final subscription = ref.listen(provider, (_, next) {
      if (next.isUploading) {
        _update(key, (row) => row.copyWith(progress: next.progress));
      }
    });
    try {
      final source = await row.file.open();
      // The page may have been left meanwhile (the upload then stops).
      if (!ref.mounted) return;
      final id = await ref
          .read(provider.notifier)
          .start(
            RecordingUploadRequest(
              studentId: student.student.id,
              halaqaId: student.halaqa.id,
              teacherId: student.halaqa.teacherId,
              type: RecordingType.official,
              surahNumber: row.surahNumber!,
              ayahFrom: row.ayahFrom!,
              ayahTo: row.ayahTo!,
              recordedAt: row.recordedAt,
              source: source,
              fileExtension: row.file.extension,
            ),
          );
      if (!ref.mounted) return;
      final result = ref.read(provider);
      if (id != null) {
        _update(
          key,
          (row) => row.copyWith(
            status: UploadRowStatus.done,
            progress: 1,
            recordingId: () => id,
          ),
        );
      } else if (result.status == RecordingUploadStatus.cancelled) {
        _update(key, (row) => row.copyWith(status: UploadRowStatus.cancelled));
      } else {
        _fail(key, result.error ?? const AppException(AppErrorCode.unknown));
      }
    } catch (error, stackTrace) {
      _fail(key, AppException.wrap(error, stackTrace));
    } finally {
      subscription.close();
    }
  }

  void _fail(String key, AppException error) => _update(
    key,
    (row) => row.copyWith(status: UploadRowStatus.failed, error: () => error),
  );

  /// Changes a row the user may still edit.
  void _edit(String key, UploadRow Function(UploadRow row) change) {
    if (state.row(key)?.status.isEditable != true) return;
    _update(key, change);
  }

  void _update(String key, UploadRow Function(UploadRow row) change) {
    if (!ref.mounted) return;
    state = UploadBatchState(
      rows: [for (final row in state.rows) row.key == key ? change(row) : row],
      running: state.running,
    );
  }

  void _setRunning(bool running) =>
      state = UploadBatchState(rows: state.rows, running: running);

  static AppErrorCode? _fileProblem(PickedAudioFile file) {
    if (AudioFormats.contentTypeFor(file.extension) == null ||
        file.sizeBytes <= 0) {
      return AppErrorCode.unsupportedFile;
    }
    if (file.sizeBytes >= AudioFormats.maxUploadBytes) {
      return AppErrorCode.fileTooLarge;
    }
    return null;
  }
}

/// The upload page's files, for a page opened from the student
/// [defaultStudentId]'s page (or none).
final uploadBatchControllerProvider = NotifierProvider.autoDispose
    .family<UploadBatchController, UploadBatchState, String?>(
      UploadBatchController.new,
    );
