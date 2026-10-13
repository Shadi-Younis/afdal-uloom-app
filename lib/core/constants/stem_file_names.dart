/// Words in the name of an exported stem that tell whose microphone it is
/// (Studio One «Export Stems» names each file after its track). Matched
/// anywhere in the name, ignoring case.
abstract final class StemFileNames {
  static const studentWords = ['student', 'talmid', 'طالب'];
  static const sheikhWords = ['sheikh', 'sheich', 'شيخ'];
}
