import 'package:afdal_uloom_tilawat/core/utils/arabic_digits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every Western digit becomes its Arabic-Indic one', () {
    expect(toArabicDigits('0123456789'), '٠١٢٣٤٥٦٧٨٩');
    expect(toArabicDigits(2026), '٢٠٢٦');
  });

  test('everything else is kept', () {
    expect(toArabicDigits('01:23'), '٠١:٢٣');
    expect(toArabicDigits('عدد ٥ و 6'), 'عدد ٥ و ٦');
    expect(toArabicDigits(''), '');
  });
}
