import 'package:afdal_uloom_tilawat/core/constants/storage_paths.dart';
import 'package:afdal_uloom_tilawat/core/data/firestore_recording_repository.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/recording.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_source.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/models/stem_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreRecordingRepository repository;

  Recording build({
    required String id,
    String studentId = 's1',
    String teacherId = 't1',
    RecordingType type = RecordingType.official,
    bool reviewed = true,
    required DateTime recordedAt,
  }) => Recording(
    id: id,
    studentId: studentId,
    halaqaId: 'h1',
    teacherId: teacherId,
    uploadedBy: type == RecordingType.official ? teacherId : studentId,
    type: type,
    surahNumber: 2,
    ayahFrom: 1,
    ayahTo: 5,
    storagePath: StoragePaths.recording(studentId, id),
    recordedAt: recordedAt,
    createdAt: DateTime(2000), // ignored by create()
    unreadFeedback: false,
    reviewed: reviewed,
  );

  /// Writes a document directly, with a chosen createdAt (create() would
  /// use the server time).
  Future<void> seed(Recording r, {required DateTime createdAt}) =>
      db.doc('recordings/${r.id}').set({
        ...r.toMap(),
        'recordedAt': Timestamp.fromDate(r.recordedAt),
        'createdAt': Timestamp.fromDate(createdAt),
      });

  setUp(() {
    db = FakeFirebaseFirestore();
    repository = FirestoreRecordingRepository(db);
  });

  test(
    'newId + create: stored under that id, createdAt is server time',
    () async {
      final id = repository.newId();
      expect(id, isNotEmpty);
      expect(repository.newId(), isNot(id));

      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final recording = build(id: id, recordedAt: DateTime(2026, 10, 5));
      await repository.create(recording);

      final raw = (await db.doc('recordings/$id').get()).data()!;
      expect(raw['storagePath'], 'recordings/s1/$id.mp3');
      expect(raw['recordedAt'], isA<Timestamp>());
      expect(raw['createdAt'], isA<Timestamp>());

      final stored = (await repository.get(id))!;
      expect(stored.createdAt.isAfter(before), isTrue);
      expect(stored, recording.copyWith(createdAt: stored.createdAt));
    },
  );

  test('get returns null for a missing recording', () async {
    expect(await repository.get('missing'), isNull);
  });

  test('watch: the recording, its changes, then null once deleted', () async {
    final recording = build(id: 'r1', recordedAt: DateTime(2026, 9, 1));
    await seed(recording, createdAt: DateTime(2026, 9, 1, 2));
    final events = <Recording?>[];
    final subscription = repository.watch('r1').listen(events.add);
    await pumpEventQueue();

    await db.doc('recordings/r1').update({'reviewed': false});
    await pumpEventQueue();
    await db.doc('recordings/r1').delete();
    await pumpEventQueue();
    await subscription.cancel();

    expect(events.map((r) => r?.reviewed), [true, false, null]);
    expect(events.first!.id, 'r1');
  });

  test('watch: a recording that never existed is null', () async {
    expect(await repository.watch('missing').first, isNull);
  });

  test('watchForStudent: only that student, newest recordedAt first', () async {
    await seed(
      build(id: 'old', recordedAt: DateTime(2026, 9, 1)),
      createdAt: DateTime(2026, 9, 1),
    );
    await seed(
      build(id: 'new', recordedAt: DateTime(2026, 10, 1)),
      createdAt: DateTime(2026, 10, 1),
    );
    await seed(
      build(id: 'other', studentId: 's2', recordedAt: DateTime(2026, 10, 2)),
      createdAt: DateTime(2026, 10, 2),
    );

    final list = await repository.watchForStudent('s1').first;
    expect(list.map((r) => r.id), ['new', 'old']);
  });

  test('a document from a newer server (unknown status or source) does not '
      'fail the list', () async {
    await seed(
      build(id: 'known', recordedAt: DateTime(2026, 9, 1)),
      createdAt: DateTime(2026, 9, 1),
    );
    await seed(
      build(id: 'new-status', recordedAt: DateTime(2026, 9, 2)),
      createdAt: DateTime(2026, 9, 2),
    );
    await db.doc('recordings/new-status').update({
      'analysis': {'status': 'transcribing'},
    });
    await seed(
      build(id: 'new-source', recordedAt: DateTime(2026, 9, 3)),
      createdAt: DateTime(2026, 9, 3),
    );
    await db.doc('recordings/new-source').update({'source': 'multitrack'});

    final list = await repository.watchForStudent('s1').first;
    expect(list.map((r) => r.id), ['new-source', 'new-status', 'known']);
    final [newSource, newStatus, _] = list;
    expect(newSource.source, RecordingSource.stereo);
    expect(newStatus.analysis?.status, AnalysisStatus.pending);
    expect(newStatus.analysis?.unknownStatus, 'transcribing');
  });

  test('watchForStudent with teacherId keeps only that teacher', () async {
    await seed(
      build(id: 'mine', recordedAt: DateTime(2026, 9, 1)),
      createdAt: DateTime(2026, 9, 1),
    );
    // Recorded while the halaqa had another teacher.
    await seed(
      build(id: 'before', teacherId: 't0', recordedAt: DateTime(2026, 8, 1)),
      createdAt: DateTime(2026, 8, 1),
    );

    final list = await repository.watchForStudent('s1', teacherId: 't1').first;
    expect(list.map((r) => r.id), ['mine']);
  });

  test('watchForStudent with a type keeps only that type (Task 12: '
      'teachers and admins ask for official only)', () async {
    await seed(
      build(id: 'official', recordedAt: DateTime(2026, 9, 2)),
      createdAt: DateTime(2026, 9, 2),
    );
    await seed(
      build(
        id: 'practice',
        type: RecordingType.practice,
        recordedAt: DateTime(2026, 9, 3),
      ),
      createdAt: DateTime(2026, 9, 3),
    );

    final official = await repository
        .watchForStudent('s1', teacherId: 't1', type: RecordingType.official)
        .first;
    expect(official.map((r) => r.id), ['official']);
    final asAdmin = await repository
        .watchForStudent('s1', type: RecordingType.official)
        .first;
    expect(asAdmin.map((r) => r.id), ['official']);
    // The student himself: both.
    final all = await repository.watchForStudent('s1').first;
    expect(all.map((r) => r.id), ['practice', 'official']);
  });

  test(
    'watchUnreviewed: official, not reviewed, oldest createdAt first',
    () async {
      Future<void> practice(
        String id,
        DateTime createdAt, {
        bool reviewed = false,
        String teacherId = 't1',
      }) => seed(
        build(
          id: id,
          type: RecordingType.practice,
          reviewed: reviewed,
          teacherId: teacherId,
          recordedAt: createdAt,
        ),
        createdAt: createdAt,
      );

      await practice('p-new', DateTime(2026, 10, 3));
      await practice('p-old', DateTime(2026, 10, 1));
      await practice('p-done', DateTime(2026, 10, 2), reviewed: true);
      await practice('p-other', DateTime(2026, 10, 2), teacherId: 't2');
      await seed(
        build(
          id: 'official',
          reviewed: false,
          recordedAt: DateTime(2026, 10, 2),
        ),
        createdAt: DateTime(2026, 10, 2),
      );
      await seed(
        build(id: 'official-done', recordedAt: DateTime(2026, 10, 2)),
        createdAt: DateTime(2026, 10, 2),
      );

      // Practice is the student's own (Task 12): never in the queue.
      final queue = await repository.watchUnreviewed('t1').first;
      expect(queue.map((r) => r.id), ['official']);
    },
  );

  test('watchForTeacherSince: that teacher\'s official ones, from that day, '
      'newest first', () async {
    Future<void> at(String id, DateTime day, {String teacherId = 't1'}) => seed(
      build(id: id, teacherId: teacherId, recordedAt: day),
      createdAt: day,
    );
    await at('before', DateTime(2026, 10, 9, 23));
    await at('first', DateTime(2026, 10, 10));
    await at('later', DateTime(2026, 10, 12, 16));
    await at('other', DateTime(2026, 10, 12), teacherId: 't2');
    await seed(
      build(
        id: 'practice',
        type: RecordingType.practice,
        recordedAt: DateTime(2026, 10, 11),
      ),
      createdAt: DateTime(2026, 10, 11),
    );

    final week = await repository
        .watchForTeacherSince('t1', DateTime(2026, 10, 10))
        .first;
    expect(week.map((r) => r.id), ['later', 'first']);
  });

  test('setSurahAndAyat: sets them, and removes the empty ones', () async {
    await seed(
      build(id: 'r1', recordedAt: DateTime(2026, 10, 1)),
      createdAt: DateTime(2026, 10, 1),
    );

    await repository.setSurahAndAyat(
      'r1',
      surahNumber: 67,
      ayahFrom: 1,
      ayahTo: 5,
    );
    var data = (await db.doc('recordings/r1').get()).data()!;
    expect((data['surahNumber'], data['ayahFrom'], data['ayahTo']), (67, 1, 5));

    await repository.setSurahAndAyat(
      'r1',
      surahNumber: 67,
      ayahFrom: null,
      ayahTo: null,
    );
    data = (await db.doc('recordings/r1').get()).data()!;
    expect(data['surahNumber'], 67);
    expect(data.containsKey('ayahFrom'), isFalse);
    expect(data.containsKey('ayahTo'), isFalse);

    await repository.setSurahAndAyat(
      'r1',
      surahNumber: null,
      ayahFrom: null,
      ayahTo: null,
    );
    final read = await repository.get('r1');
    expect(read!.surahNumber, isNull);
    expect(read.ayahFrom, isNull);
  });

  test('setSurahAndAyat on a missing recording throws AppException', () {
    expect(
      repository.setSurahAndAyat(
        'missing',
        surahNumber: 1,
        ayahFrom: null,
        ayahTo: null,
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('markFeedbackRead, setReviewed both ways and delete', () async {
    final r = build(
      id: 'r1',
      type: RecordingType.practice,
      reviewed: false,
      recordedAt: DateTime(2026, 10, 1),
    );
    await seed(r, createdAt: DateTime(2026, 10, 1));
    await db.doc('recordings/r1').update({'unreadFeedback': true});

    await repository.markFeedbackRead('r1');
    await repository.setReviewed('r1', reviewed: true);
    final updated = (await repository.get('r1'))!;
    expect(updated.unreadFeedback, isFalse);
    expect(updated.reviewed, isTrue);
    await repository.setReviewed('r1', reviewed: false);
    expect((await repository.get('r1'))!.reviewed, isFalse);

    await repository.delete('r1');
    expect(await repository.get('r1'), isNull);
  });

  test('a malformed document becomes AppException(invalidData)', () async {
    await db.doc('recordings/bad').set({'studentId': 's1', 'surahNumber': 0});
    await expectLater(
      repository.get('bad'),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppErrorCode.invalidData,
        ),
      ),
    );
  });

  test('a two-file recording: source and stemPaths stored, the server\'s '
      'analysis read back', () async {
    final id = repository.newId();
    final recording = build(id: id, recordedAt: DateTime(2026, 10, 5)).copyWith(
      source: RecordingSource.stems,
      stemPaths: StemPaths(
        student: 'recordings/s1/$id.student.wav',
        sheikh: 'recordings/s1/$id.sheikh.mp3',
      ),
    );
    await repository.create(recording);

    final stored = (await db.doc('recordings/$id').get()).data()!;
    expect(stored['source'], 'stems');
    expect(stored['stemPaths'], {
      'student': 'recordings/s1/$id.student.wav',
      'sheikh': 'recordings/s1/$id.sheikh.mp3',
    });
    expect(stored['storagePath'], 'recordings/s1/$id.mp3');

    // What the server writes once joined and analysed; whole dB arrive as int.
    await db.doc('recordings/$id').update({
      'analysis': {
        'status': 'done',
        'segmentCount': 2,
        'swapped': true,
        'bleedDb': -15,
        'separationDb': 30.1,
        'stemsLagMs': 0,
      },
    });
    final read = (await repository.get(id))!;
    expect(read.source, RecordingSource.stems);
    expect(read.stemPaths, recording.stemPaths);
    expect(read.analysis?.status, AnalysisStatus.done);
    expect(read.analysis?.swapped, isTrue);
    expect(read.analysis?.bleedDb, -15.0);
    expect(read.analysis?.separationDb, 30.1);
    expect(read.analysis?.stemsLagMs, 0);
    expect(read.hasAudio, isTrue);
  });

  test('a one-file recording writes no source', () async {
    final id = repository.newId();
    await repository.create(build(id: id, recordedAt: DateTime(2026, 10, 5)));
    final stored = (await db.doc('recordings/$id').get()).data()!;
    expect(stored.containsKey('source'), isFalse);
    expect(stored.containsKey('stemPaths'), isFalse);
    expect((await repository.get(id))!.source, RecordingSource.stereo);
  });
}
