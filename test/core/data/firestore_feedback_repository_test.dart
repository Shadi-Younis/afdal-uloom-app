import 'package:afdal_uloom_tilawat/core/data/firestore_feedback_repository.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreFeedbackRepository repository;

  FeedbackNote note(String text, {int? atSecond, int? rating}) => FeedbackNote(
    id: '', // ignored by add()
    teacherId: 't1',
    note: text,
    atSecond: atSecond,
    rating: rating,
    createdAt: DateTime(2000), // ignored by add()
  );

  setUp(() async {
    db = FakeFirebaseFirestore();
    repository = FirestoreFeedbackRepository(db);
    await db.doc('recordings/r1').set({'unreadFeedback': false});
  });

  test('add stores the note and sets unreadFeedback in one batch', () async {
    await repository.add('r1', note('انتبه للمدّ', atSecond: 42, rating: 4));

    final recording = await db.doc('recordings/r1').get();
    expect(recording.data()!['unreadFeedback'], isTrue);

    final notes = await db.collection('recordings/r1/feedback').get();
    expect(notes.docs, hasLength(1));
    final data = notes.docs.single.data();
    expect(data['note'], 'انتبه للمدّ');
    expect(data['atSecond'], 42);
    expect(data['rating'], 4);
    expect(data['createdAt'], isA<Timestamp>());
  });

  // Atomicity itself is a server guarantee (the fake's batches are not
  // atomic); the emulator rules tests write the same batch.
  test('add on a missing recording throws AppException', () async {
    await expectLater(
      repository.add('missing', note('x')),
      throwsA(isA<AppException>()),
    );
  });

  test('watch maps the notes, oldest first', () async {
    Future<void> seed(String id, String text, DateTime createdAt) =>
        db.doc('recordings/r1/feedback/$id').set({
          'teacherId': 't1',
          'note': text,
          'atSecond': null,
          'rating': null,
          'createdAt': Timestamp.fromDate(createdAt),
        });
    await seed('b', 'الثانية', DateTime(2026, 10, 2));
    await seed('a', 'الأولى', DateTime(2026, 10, 1));

    final notes = await repository.watch('r1').first;
    expect(notes.map((n) => n.id), ['a', 'b']);
    expect(notes.first.note, 'الأولى');
    expect(notes.first.createdAt, DateTime(2026, 10, 1));
  });

  test('delete removes one note', () async {
    await repository.add('r1', note('x'));
    final id = (await repository.watch('r1').first).single.id;

    await repository.delete('r1', id);
    expect(await repository.watch('r1').first, isEmpty);
  });
}
