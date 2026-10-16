import '../constants/stem_file_names.dart';
import '../models/stem_role.dart';

/// Whose microphone the file [fileName] is, from the words in its name
/// (StemFileNames), e.g. `S014_002_001-020 - Student.wav`; null when it
/// names neither, or both.
StemRole? stemRoleOfName(String fileName) {
  final name = fileName.toLowerCase();
  bool names(List<String> words) => words.any(name.contains);
  return switch ((
    names(StemFileNames.studentWords),
    names(StemFileNames.sheikhWords),
  )) {
    (true, false) => StemRole.student,
    (false, true) => StemRole.sheikh,
    _ => null,
  };
}
