import 'dart:async';

import 'package:afdal_uloom_tilawat/core/models/halaqa.dart';
import 'package:afdal_uloom_tilawat/core/repositories/halaqa_repository.dart';

/// A [HalaqaRepository] over an in-memory map. Streams emit again after
/// every write.
///
/// - [watchError]: emitted by every watch instead of data.
/// - [writeError]: what create / rename throw.
/// - [gate]: when set, writes wait for it (to test loading states).
/// - [watchGate]: when set, streams emit nothing until it completes.
class FakeHalaqaRepository implements HalaqaRepository {
  FakeHalaqaRepository([List<Halaqa> halaqat = const []])
    : halaqat = {for (final h in halaqat) h.id: h};

  final Map<String, Halaqa> halaqat;
  Object? watchError;
  Object? writeError;
  Completer<void>? gate;
  Completer<void>? watchGate;

  final createCalls = <(String name, String teacherId)>[];
  final renameCalls = <(String id, String name)>[];

  final _changed = StreamController<void>.broadcast();

  /// Adds or replaces [halaqa]; every open stream emits again.
  void put(Halaqa halaqa) {
    halaqat[halaqa.id] = halaqa;
    _changed.add(null);
  }

  @override
  Stream<List<Halaqa>> watchAll() => _live(() => _sorted((_) => true));

  @override
  Stream<List<Halaqa>> watchForTeacher(String teacherId) =>
      _live(() => _sorted((h) => h.teacherId == teacherId));

  @override
  Stream<Halaqa?> watch(String halaqaId) => _live(() => halaqat[halaqaId]);

  @override
  Future<String> create({
    required String name,
    required String teacherId,
  }) async {
    createCalls.add((name, teacherId));
    await gate?.future;
    if (writeError case final error?) throw error;
    final id = 'halaqa-new-${createCalls.length}';
    put(Halaqa(id: id, name: name, teacherId: teacherId));
    return id;
  }

  @override
  Future<void> rename(String halaqaId, String name) async {
    renameCalls.add((halaqaId, name));
    await gate?.future;
    if (writeError case final error?) throw error;
    put(halaqat[halaqaId]!.copyWith(name: name));
  }

  List<Halaqa> _sorted(bool Function(Halaqa) test) =>
      halaqat.values.where(test).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Stream<T> _live<T>(T Function() read) async* {
    await watchGate?.future;
    if (watchError case final error?) throw error;
    yield read();
    yield* _changed.stream.map((_) => read());
  }
}
