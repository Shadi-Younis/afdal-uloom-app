import 'package:afdal_uloom_tilawat/core/utils/school_week.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the school week starts on Saturday at midnight', () {
    // 2026-10-10 is a Saturday.
    final saturday = DateTime(2026, 10, 10);
    expect(startOfSchoolWeek(DateTime(2026, 10, 10, 15)), saturday);
    expect(startOfSchoolWeek(DateTime(2026, 10, 12, 9)), saturday);
    expect(startOfSchoolWeek(DateTime(2026, 10, 16, 23, 59)), saturday);
    expect(startOfSchoolWeek(DateTime(2026, 10, 17)), DateTime(2026, 10, 17));
  });

  test('across a month and a year', () {
    expect(startOfSchoolWeek(DateTime(2026, 11, 2)), DateTime(2026, 10, 31));
    expect(startOfSchoolWeek(DateTime(2027, 1, 1)), DateTime(2026, 12, 26));
  });
}
