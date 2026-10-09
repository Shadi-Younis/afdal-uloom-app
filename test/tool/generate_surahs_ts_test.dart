import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/generate_surahs_ts.dart';

void main() {
  test('functions/src/lib/surahs.ts matches the Dart surah list', () {
    // Line endings may differ after a Windows checkout.
    final committed = File(
      surahsTsPath,
    ).readAsStringSync().replaceAll('\r\n', '\n');
    expect(
      committed,
      renderSurahsTs(),
      reason: 'Run: dart run tool/generate_surahs_ts.dart',
    );
  });
}
