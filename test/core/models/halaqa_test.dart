import 'package:afdal_uloom_tilawat/core/models/halaqa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const halaqa = Halaqa(id: 'h1', name: 'حلقة الفجر', teacherId: 't1');

  test('toMap uses the contract field names and leaves out the id', () {
    expect(halaqa.toMap(), {'name': 'حلقة الفجر', 'teacherId': 't1'});
  });

  test('round trip through toMap and fromMap', () {
    expect(Halaqa.fromMap('h1', halaqa.toMap()), halaqa);
  });

  test('missing or mistyped field throws FormatException', () {
    expect(() => Halaqa.fromMap('h1', {'name': 'حلقة'}), throwsFormatException);
    expect(
      () => Halaqa.fromMap('h1', {'name': 7, 'teacherId': 't1'}),
      throwsFormatException,
    );
  });

  test('copyWith, equality and hashCode', () {
    final moved = halaqa.copyWith(teacherId: 't2');
    expect(moved.teacherId, 't2');
    expect(moved.name, halaqa.name);
    expect(moved, isNot(halaqa));
    expect(halaqa.copyWith(), halaqa);
    expect(halaqa.copyWith().hashCode, halaqa.hashCode);
    expect(halaqa.toString(), contains('h1'));
  });
}
