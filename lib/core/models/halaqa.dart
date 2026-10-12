import '../constants/firestore_paths.dart';
import '../utils/map_reader.dart';

/// A study circle (`halaqat/{id}`) with exactly one teacher.
class Halaqa {
  const Halaqa({
    required this.id,
    required this.name,
    required this.teacherId,
    this.teacherName,
  });

  /// Throws [FormatException] for a missing field or a wrong type.
  factory Halaqa.fromMap(String id, Map<String, dynamic> map) => Halaqa(
    id: id,
    name: readRequired<String>(map, Fields.name),
    teacherId: readRequired<String>(map, Fields.teacherId),
    teacherName: readOptional<String>(map, Fields.teacherName),
  );

  /// The document id; not stored in the document.
  final String id;
  final String name;
  final String teacherId;

  /// A copy of the teacher's `fullName`, for the students, who may not read
  /// teachers' profiles. Written when the halaqa is created and kept equal
  /// by the server; null for halaqat created before it existed, until their
  /// teacher is set again («تغيير المعلم»).
  final String? teacherName;

  Map<String, dynamic> toMap() => {
    Fields.name: name,
    Fields.teacherId: teacherId,
    Fields.teacherName: ?teacherName,
  };

  /// [teacherName] cannot be cleared to null through copyWith.
  Halaqa copyWith({
    String? id,
    String? name,
    String? teacherId,
    String? teacherName,
  }) => Halaqa(
    id: id ?? this.id,
    name: name ?? this.name,
    teacherId: teacherId ?? this.teacherId,
    teacherName: teacherName ?? this.teacherName,
  );

  @override
  bool operator ==(Object other) =>
      other is Halaqa &&
      other.id == id &&
      other.name == name &&
      other.teacherId == teacherId &&
      other.teacherName == teacherName;

  @override
  int get hashCode => Object.hash(id, name, teacherId, teacherName);

  @override
  String toString() =>
      'Halaqa(id: $id, name: $name, teacherId: $teacherId, '
      'teacherName: $teacherName)';
}
