import '../constants/storage_paths.dart';

/// Which microphone a file of a two-file recording comes from. [value] is
/// its key in `recordings/{id}.stemPaths` and its part of the file name in
/// Storage (StoragePaths.stem).
enum StemRole {
  /// «صوت الطالب»: joined into the LEFT channel.
  student(StoragePaths.stemStudent),

  /// «صوت الشيخ»: joined into the RIGHT channel.
  sheikh(StoragePaths.stemSheikh);

  const StemRole(this.value);

  final String value;

  /// The other microphone.
  StemRole get other => this == student ? sheikh : student;
}
