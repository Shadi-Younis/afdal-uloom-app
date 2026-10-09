import '../models/audio_source.dart';
import '../models/recording_type.dart';

/// What the teacher or student fills in to upload one recording. The
/// uploader, the id, the storagePath and the flags are added by
/// RecordingUploadController.
class RecordingUploadRequest {
  const RecordingUploadRequest({
    required this.studentId,
    required this.halaqaId,
    required this.teacherId,
    required this.type,
    required this.surahNumber,
    required this.ayahFrom,
    required this.ayahTo,
    required this.recordedAt,
    required this.source,
    required this.fileExtension,
    this.durationSec,
  });

  final String studentId;

  /// The student's halaqa and its teacher (firestore.rules checks both).
  final String halaqaId;
  final String teacherId;
  final RecordingType type;
  final int surahNumber;
  final int ayahFrom;
  final int ayahTo;
  final DateTime recordedAt;
  final AudioSource source;

  /// Of the picked or recorded file, without the dot, e.g. `mp3`; decides
  /// the storagePath and the content type.
  final String fileExtension;
  final int? durationSec;
}
