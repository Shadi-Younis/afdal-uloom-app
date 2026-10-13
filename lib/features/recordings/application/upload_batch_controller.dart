import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/my_students_providers.dart';
import '../../../core/application/recording_upload_controller.dart';
import '../../../core/application/recording_upload_status.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/picked_audio_file.dart';
import '../../../core/models/recording_source.dart';
import '../../../core/models/stem_role.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/service_providers.dart';
import 'stem_files.dart';
import 'upload_batch_state.dart';
import 'upload_row_builders.dart';
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
///
/// A row can switch to two-file mode («ملفين: الطالب + الشيخ»): the
/// student's and the sheikh's files (Studio One «Export Stems»), placed by
/// their names or the order dropped, checked for equal lengths, and
/// uploaded together as one recording.
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
        newUploadRow(
          key: 'upload-${_nextKey++}',
          file: file,
          students: students,
          defaultStudentId: defaultStudentId,
          today: today,
        ),
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

  /// «ملف واحد (يسار/يمين)» or «ملفين: الطالب + الشيخ». The first switch
  /// to two files puts the row's file where its name says (else the
  /// student's); switching back keeps both files for later.
  void setSource(String key, RecordingSource source) {
    final row = state.row(key);
    if (row == null || !row.status.isEditable || row.fileProblem != null) {
      return;
    }
    _edit(key, (row) => row.copyWith(source: source));
    if (source == RecordingSource.stems &&
        row.studentFile == null &&
        row.sheikhFile == null) {
      setStems(key, [row.file]);
    }
  }

  /// Puts [files] into the two-file slots of [key] (placeStems): [into]
  /// is the zone they were dropped on or picked for. Their names fill in
  /// what the row still lacks, and their lengths are read.
  void setStems(String key, List<PickedAudioFile> files, {StemRole? into}) {
    final row = state.row(key);
    if (row == null || !row.isStems || !row.status.isEditable) return;
    final placed = placeStems(row, files, into: into);
    if (placed.isEmpty) return;
    final students = ref.read(myStudentsProvider).value ?? const [];
    final today = ref.read(clockProvider)();
    _edit(key, (row) {
      var next = row;
      for (final (role, file) in placed) {
        next = next.withStem(role, file, null);
      }
      return prefilledFrom(
        next,
        [for (final (_, file) in placed) file],
        students,
        today,
      );
    });
    for (final (_, file) in placed) {
      _readDuration(key, file);
    }
  }

  /// «تبديل»: the student's file becomes the sheikh's and the other way.
  void swapStems(String key) => _edit(
    key,
    (row) => row.copyWith(
      studentFile: () => row.sheikhFile,
      sheikhFile: () => row.studentFile,
      studentDuration: () => row.sheikhDuration,
      sheikhDuration: () => row.studentDuration,
    ),
  );

  /// Shows how long [file] is, in whichever slot of [key] it is by then.
  Future<void> _readDuration(String key, PickedAudioFile file) async {
    final duration = await ref
        .read(audioDurationReaderProvider)
        .durationOf(file);
    if (!ref.mounted || duration == null) return;
    _update(key, (row) {
      for (final role in StemRole.values) {
        if (identical(row.stemFile(role), file)) {
          return row.withStem(role, file, duration);
        }
      }
      return row;
    });
  }

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
        stemProgress: () => null,
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
        _update(
          key,
          (row) => row.copyWith(
            progress: next.progress,
            stemProgress: () => next.stemProgress,
          ),
        );
      }
    });
    try {
      final request = await uploadRequestOf(row, student);
      // The page may have been left meanwhile (the upload then stops).
      if (!ref.mounted) return;
      final id = await ref.read(provider.notifier).start(request);
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
}

/// The upload page's files, for a page opened from the student
/// [defaultStudentId]'s page (or none).
final uploadBatchControllerProvider = NotifierProvider.autoDispose
    .family<UploadBatchController, UploadBatchState, String?>(
      UploadBatchController.new,
    );
