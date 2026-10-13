import 'package:afdal_uloom_tilawat/core/models/stem_role.dart';
import 'package:afdal_uloom_tilawat/core/utils/stem_role_of_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('student, talmid or طالب: the student, any case', () {
    for (final name in [
      'S014_002_001-020 - Student.wav',
      'STUDENT.mp3',
      'talmid_1.wav',
      'Talmid.wav',
      'صوت الطالب.mp3',
    ]) {
      expect(stemRoleOfName(name), StemRole.student, reason: name);
    }
  });

  test('sheikh, sheich or شيخ: the sheikh, any case', () {
    for (final name in [
      'S014_002_001-020 - Sheikh.wav',
      'sheich.mp3',
      'SHEIKH mic.wav',
      'الشيخ.mp3',
    ]) {
      expect(stemRoleOfName(name), StemRole.sheikh, reason: name);
    }
  });

  test('neither, or both: unknown', () {
    expect(stemRoleOfName('S014_002_001-020.wav'), isNull);
    expect(stemRoleOfName('Audio 1.wav'), isNull);
    expect(stemRoleOfName('student and sheikh.wav'), isNull);
  });

  test('each role knows the other and its Storage name', () {
    expect(StemRole.student.other, StemRole.sheikh);
    expect(StemRole.sheikh.other, StemRole.student);
    expect(StemRole.values.map((r) => r.value), ['student', 'sheikh']);
  });
}
