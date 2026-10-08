import 'package:afdal_uloom_tilawat/core/data/firestore_halaqa_repository.dart';
import 'package:afdal_uloom_tilawat/core/models/halaqa.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreHalaqaRepository repository;

  setUp(() {
    db = FakeFirebaseFirestore();
    repository = FirestoreHalaqaRepository(db);
  });

  test('create stores name and teacherId and returns the new id', () async {
    final id = await repository.create(name: 'حلقة الفجر', teacherId: 't1');
    final doc = await db.doc('halaqat/$id').get();
    expect(doc.data(), {'name': 'حلقة الفجر', 'teacherId': 't1'});
  });

  test('watch maps the document, or null when missing', () async {
    final id = await repository.create(name: 'حلقة الفجر', teacherId: 't1');
    expect(
      await repository.watch(id).first,
      Halaqa(id: id, name: 'حلقة الفجر', teacherId: 't1'),
    );
    expect(await repository.watch('missing').first, isNull);
  });

  test('watchAll and watchForTeacher are sorted by name', () async {
    await repository.create(name: 'حلقة العصر', teacherId: 't1');
    await repository.create(name: 'حلقة الفجر', teacherId: 't2');
    await repository.create(name: 'حلقة الضحى', teacherId: 't1');

    final all = await repository.watchAll().first;
    expect(all.map((h) => h.name), ['حلقة الضحى', 'حلقة العصر', 'حلقة الفجر']);

    final mine = await repository.watchForTeacher('t1').first;
    expect(mine.map((h) => h.name), ['حلقة الضحى', 'حلقة العصر']);
  });

  test('rename changes the name only', () async {
    final id = await repository.create(name: 'حلقة', teacherId: 't1');
    await repository.rename(id, 'حلقة المغرب');
    expect(
      await repository.watch(id).first,
      Halaqa(id: id, name: 'حلقة المغرب', teacherId: 't1'),
    );
  });
}
