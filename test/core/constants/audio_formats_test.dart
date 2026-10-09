import 'dart:io';

import 'package:afdal_uloom_tilawat/core/constants/app_strings.dart';
import 'package:afdal_uloom_tilawat/core/constants/audio_formats.dart';
import 'package:afdal_uloom_tilawat/core/utils/arabic_digits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the six accepted extensions and their content types', () {
    expect(AudioFormats.contentTypes, {
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'webm': 'audio/webm',
    });
  });

  test('every content type is audio/*, as storage.rules requires', () {
    for (final type in AudioFormats.contentTypes.values) {
      expect(type, startsWith('audio/'));
    }
  });

  test('contentTypeFor ignores case and refuses unknown extensions', () {
    expect(AudioFormats.contentTypeFor('MP3'), 'audio/mpeg');
    expect(AudioFormats.contentTypeFor('flac'), isNull);
    expect(AudioFormats.contentTypeFor(''), isNull);
  });

  test('firestore.rules allows exactly these extensions in storagePath', () {
    final rules = File('firestore.rules').readAsStringSync();
    final allowed = RegExp(r"prefix \+ '(\w+)'")
        .allMatches(rules)
        .map((m) => m.group(1))
        .toSet();
    expect(allowed, AudioFormats.contentTypes.keys.toSet());
  });

  test('100 MiB, the same limit as storage.rules and the error message', () {
    expect(AudioFormats.maxUploadBytes, 100 * 1024 * 1024);
    expect(
      File('storage.rules').readAsStringSync(),
      contains('return 100 * 1024 * 1024;'),
    );
    expect(AppStrings.errorFileTooLarge, contains(toArabicDigits(100)));
  });
}
