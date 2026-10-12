import 'package:afdal_uloom_tilawat/core/models/feedback_kind.dart';
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
      'kind': 'text',
      'atSecond': 42,
      'rating': 4,
      'createdAt': createdAt,
    });
  });

  FeedbackNote voice({String note = '', int at = 83, int? end = 91}) =>
      FeedbackNote(
        id: 'v1',
        teacherId: 't1',
        note: note,
        kind: FeedbackKind.voice,
        atSecond: at,
        endSecond: end,
        createdAt: createdAt,
      );

  test('a voice marker: its span, empty text allowed, round trip', () {
    final marker = voice();
    expect(marker.isVoice, isTrue);
    expect(marker.toMap(), {
      'teacherId': 't1',
      'note': '',
      'kind': 'voice',
      'atSecond': 83,
      'endSecond': 91,
      'rating': null,
      'createdAt': createdAt,
    });
    expect(FeedbackNote.fromMap('v1', marker.toMap()), marker);
    final edited = marker.copyWith(
      note: 'المدّ هنا ست حركات',
      updatedAt: createdAt.add(const Duration(days: 1)),
    );
    expect(FeedbackNote.fromMap('v1', edited.toMap()), edited);
  });

  test('a note written before Task 09 (no kind) is text', () {
    final old = build().toMap()..remove('kind');
    expect(FeedbackNote.fromMap('f1', old).kind, FeedbackKind.text);
  });

  test('an unknown kind throws FormatException', () {
    expect(
      () => FeedbackNote.fromMap('f1', {...build().toMap(), 'kind': 'video'}),
      throwsFormatException,
    );
  });

  test('a text note needs text; endSecond needs a start before it', () {
    expect(
      () => FeedbackNote(
        id: 'f1',
        teacherId: 't1',
        note: '',
        createdAt: createdAt,
      ),
      throwsArgumentError,
    );
    expect(() => voice(end: 82), throwsArgumentError);
    expect(() => voice(end: 83), returnsNormally);
    expect(
      () => FeedbackNote(
        id: 'v1',
        teacherId: 't1',
        note: '',
        kind: FeedbackKind.voice,
        endSecond: 4,
        createdAt: createdAt,
      ),
      throwsArgumentError,
    );
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
