/// Combines several [AsyncValue]s into one, for providers that derive data
/// from more than one stream.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first error among [a] and [b] wins, then loading; data only when
/// both have it.
AsyncValue<R> combine2<A, B, R>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  R Function(A a, B b) combine,
) {
  for (final value in [a, b]) {
    if (value case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
  }
  if (a case AsyncData(value: final av)) {
    if (b case AsyncData(value: final bv)) return AsyncData(combine(av, bv));
  }
  return const AsyncLoading();
}

/// [combine2] for three values.
AsyncValue<R> combine3<A, B, C, R>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  AsyncValue<C> c,
  R Function(A a, B b, C c) combine,
) => combine2(
  combine2(a, b, (av, bv) => (av, bv)),
  c,
  (ab, cv) => combine(ab.$1, ab.$2, cv),
);
