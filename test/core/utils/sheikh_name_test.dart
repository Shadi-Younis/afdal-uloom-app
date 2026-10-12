import 'package:afdal_uloom_tilawat/core/utils/sheikh_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('«الشيخ» and the name', () {
    expect(sheikhName('محمود'), 'الشيخ محمود');
    expect(sheikhName('  عبد الرحمن  '), 'الشيخ عبد الرحمن');
  });

  test('a name with the title already is not titled twice', () {
    expect(sheikhName('الشيخ محمود'), 'الشيخ محمود');
  });

  test('no name yet (a halaqa from before Task 10): «الشيخ»', () {
    expect(sheikhName(null), 'الشيخ');
    expect(sheikhName(''), 'الشيخ');
    expect(sheikhName('   '), 'الشيخ');
  });
}
