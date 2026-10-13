import '../../../core/models/recording.dart';
import '../../../core/models/recording_type.dart';

/// The chips above the student's list: «الكل / رسمي / تدريب».
enum RecordingsFilter {
  all,
  official,
  practice;

  bool matches(Recording recording) => switch (this) {
    all => true,
    official => recording.type == RecordingType.official,
    practice => recording.type == RecordingType.practice,
  };
}
