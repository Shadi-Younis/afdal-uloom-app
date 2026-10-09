import 'package:afdal_uloom_tilawat/core/utils/student_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextStudentCode', () {
    test('no students yet: S001', () {
      expect(nextStudentCode([]), 'S001');
      expect(nextStudentCode([null, null]), 'S001');
    });

    test('one above the highest code, 3 digits', () {
      expect(nextStudentCode(['S001', 'S002', 'S012']), 'S013');
      expect(nextStudentCode(['S099']), 'S100');
    });

    test('gaps are not reused: the highest code wins', () {
      expect(nextStudentCode(['S001', 'S005', 'S003']), 'S006');
      expect(nextStudentCode(['S040']), 'S041');
    });

    test('order does not matter', () {
      expect(nextStudentCode(['S012', 'S003', 'S007']), 'S013');
    });

    test('teachers (null) and malformed codes are ignored', () {
      expect(nextStudentCode([null, 'S004', 'x12', 's010', 'S12']), 'S005');
    });

    test('S998 -> S999; at S999 no 3-digit code is left', () {
      expect(nextStudentCode(['S998']), 'S999');
      expect(nextStudentCode(['S001', 'S999']), isNull);
    });

    test('a longer code above 999 (accepted by the server) also ends it', () {
      expect(nextStudentCode(['S005', 'S1200']), isNull);
    });
  });

  group('usernameForStudentCode', () {
    test('is the code in lower case', () {
      expect(usernameForStudentCode('S013'), 's013');
      expect(usernameForStudentCode(' S100 '), 's100');
    });
  });
}
