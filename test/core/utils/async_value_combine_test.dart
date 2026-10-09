import 'package:afdal_uloom_tilawat/core/utils/async_value_combine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const one = AsyncData(1);
  const two = AsyncData(2);
  final error = AsyncError<int>('boom', StackTrace.empty);

  test('data only when every value has data', () {
    expect(combine2(one, two, (a, b) => a + b), const AsyncData(3));
    expect(
      combine3(one, two, const AsyncData(3), (a, b, c) => a + b + c),
      const AsyncData(6),
    );
  });

  test('loading while any value is loading', () {
    expect(
      combine2(one, const AsyncLoading<int>(), (a, b) => a + b),
      isA<AsyncLoading<int>>(),
    );
    expect(
      combine3(one, two, const AsyncLoading<int>(), (a, b, c) => a + b + c),
      isA<AsyncLoading<int>>(),
    );
  });

  test('an error wins over loading and data', () {
    expect(
      combine2(const AsyncLoading<int>(), error, (a, b) => a + b).error,
      'boom',
    );
    expect(combine3(one, two, error, (a, b, c) => a + b + c).error, 'boom');
  });
}
