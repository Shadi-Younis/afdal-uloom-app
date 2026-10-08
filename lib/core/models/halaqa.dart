import '../constants/firestore_paths.dart';
import '../utils/map_reader.dart';

/// A study circle (`halaqat/{id}`) with exactly one teacher.
class Halaqa {
  const Halaqa({required this.id, required this.name, required this.teacherId});

  /// Throws [FormatException] for a missing field or a wrong type.
  factory Halaqa.fromMap(String id, Map<String, dynamic> map) => Halaqa(
    id: id,
    name: readRequired<String>(map, Fields.name),
    teacherId: readRequired<String>(map, Fields.teacherId),
  );

  /// The document id; not stored in the document.
  final String id;
  final String name;
  final String teacherId;

  Map<String, dynamic> toMap() => {
    Fields.name: name,
    Fields.teacherId: teacherId,
  };

  Halaqa copyWith({String? id, String? name, String? teacherId}) => Halaqa(
    id: id ?? this.id,
    name: name ?? this.name,
    teacherId: teacherId ?? this.teacherId,
  );

  @override
  bool operator ==(Object other) =>
      other is Halaqa &&
      other.id == id &&
      other.name == name &&
      other.teacherId == teacherId;

  @override
  int get hashCode => Object.hash(id, name, teacherId);

  @override
  String toString() => 'Halaqa(id: $id, name: $name, teacherId: $teacherId)';
}
