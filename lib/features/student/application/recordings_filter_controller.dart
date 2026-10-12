import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recordings_filter.dart';

/// The selected chip above the student's list; «الكل» at first.
class RecordingsFilterController extends Notifier<RecordingsFilter> {
  @override
  RecordingsFilter build() => RecordingsFilter.all;

  void select(RecordingsFilter filter) => state = filter;
}

final recordingsFilterProvider =
    NotifierProvider.autoDispose<RecordingsFilterController, RecordingsFilter>(
      RecordingsFilterController.new,
    );
