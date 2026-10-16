import '../constants/firestore_paths.dart';
import '../utils/map_reader.dart';

/// Where the two files of a two-file recording are uploaded
/// (`recordings/{id}.stemPaths`), see StoragePaths.stem. The server joins
/// them into the recording's storagePath, then deletes them.
class StemPaths {
  const StemPaths({required this.student, required this.sheikh});

  /// Throws [FormatException] for a missing field or a wrong type.
  factory StemPaths.fromMap(Map<String, dynamic> map) => StemPaths(
    student: readRequired<String>(map, Fields.stemStudent),
    sheikh: readRequired<String>(map, Fields.stemSheikh),
  );

  /// The student's microphone: `recordings/{studentId}/{id}.student.{ext}`.
  final String student;

  /// The sheikh's microphone: `recordings/{studentId}/{id}.sheikh.{ext}`.
  final String sheikh;

  Map<String, dynamic> toMap() => {
    Fields.stemStudent: student,
    Fields.stemSheikh: sheikh,
  };

  @override
  bool operator ==(Object other) =>
      other is StemPaths && other.student == student && other.sheikh == sheikh;

  @override
  int get hashCode => Object.hash(student, sheikh);

  @override
  String toString() => 'StemPaths(student: $student, sheikh: $sheikh)';
}
