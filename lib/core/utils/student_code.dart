/// Student codes (`S013`) and the usernames derived from them.
library;

import '../constants/model_limits.dart';

final _studentCode = RegExp(ModelLimits.studentCodePattern);

/// The code for the next new student: one above the highest existing
/// number, as `S` + 3 digits. Gaps left by earlier codes are not reused,
/// so a code never points at two students over time. Null when no 3-digit
/// code is left (S999 or higher exists). Ignores null and malformed codes.
String? nextStudentCode(Iterable<String?> existingCodes) {
  var highest = 0;
  for (final code in existingCodes) {
    if (code == null || !_studentCode.hasMatch(code)) continue;
    final number = int.parse(
      code.substring(ModelLimits.studentCodePrefix.length),
    );
    if (number > highest) highest = number;
  }
  final next = highest + 1;
  if (next > ModelLimits.studentCodeMaxNumber) return null;
  return ModelLimits.studentCodePrefix +
      next.toString().padLeft(ModelLimits.studentCodeDigits, '0');
}

/// The default username of a student: their code in lower case
/// (`S013` → `s013`).
String usernameForStudentCode(String code) => code.trim().toLowerCase();
