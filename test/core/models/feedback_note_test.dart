import 'package:afdal_uloom_tilawat/core/models/feedback_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 6, 9);

  FeedbackNote build({int? atSecond = 42, int? rating = 4}) => FeedbackNote(
    id: 'f1',
    teacherId: 't1',
    note: 'انتبه للمدّ',
    atSecond: atSecond,
    rating: rating,
    createdAt: createdAt,
  );

  test('toMap uses the contract field names and leaves out the id', () {
    expect(build().toMap(), {
      'teacherId': 't1',
      'note': 'انتبه للمدّ',
      'atSecond': 42,
      'rating': 4,
      'createdAt': createdAt,
    });
  });

  test('round trip through toMap and fromMap', () {
    final note = build();
    expect(FeedbackNote.fromMap('f1', note.toMap()), note);
    final plain = build(atSecond: null, rating: null);
    expect(FeedbackNote.fromMap('f1', plain.toMap()), plain);
  });

  test('missing or mistyped field throws FormatException', () {
    final map = build().toMap()..remove('note');
    expect(() => FeedbackNote.fromMap('f1', map), throwsFormatException);
    expect(
      () => FeedbackNote.fromMap('f1', {...build().toMap(), 'rating': 4.5}),
      throwsFormatException,
    );
  });

  test('accepts the edges of every range', () {
    expect(() => build(atSecond: 0), returnsNormally);
    expect(() => build(rating: 1), returnsNormally);
    expect(() => build(rating: 5), returnsNormally);
  });

  test('invalid rating or atSecond throws ArgumentError', () {
    expect(() => build(rating: 0), throwsArgumentError);
    expect(() => build(rating: 6), throwsArgumentError);
    expect(() => build(atSecond: -1), throwsArgumentError);
  });

  test('copyWith, equality and hashCode', () {
    final note = build();
    final edited = note.copyWith(note: 'أحسنت');
    expect(edited.note, 'أحسنت');
    expect(edited, isNot(note));
    expect(note.copyWith(), note);
    expect(note.copyWith().hashCode, note.hashCode);
    expect(note.toString(), contains('f1'));
  });
}
