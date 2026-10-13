/// The `recordings/{id}.analysis.error` codes the app tells apart. Every
/// other code is only for the logs («تعذّر تحليل التسجيل»). Mirrors
/// functions/src/lib/stems.ts (StemsProblem) and the merge's own failures.
abstract final class AnalysisErrors {
  /// Every failure to join two stems starts with this: the recording then
  /// has no audio at all (its storagePath was never written).
  static const stemsPrefix = 'stems_';

  /// The two files' lengths differ by more than a second.
  static const stemsLengthMismatch = 'stems_length_mismatch';

  /// The sheikh's file is more than 100 ms early or late.
  static const stemsMisaligned = 'stems_misaligned';
}
