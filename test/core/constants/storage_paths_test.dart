import 'package:afdal_uloom_tilawat/core/constants/storage_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recording path defaults to mp3', () {
    expect(StoragePaths.recording('s1', 'r1'), 'recordings/s1/r1.mp3');
  });

  test('recording path takes another extension', () {
    expect(
      StoragePaths.recording('s1', 'r1', extension: 'm4a'),
      'recordings/s1/r1.m4a',
    );
  });

  test('the playback copy sits next to the recording', () {
    expect(StoragePaths.playback('s1', 'r1'), 'recordings/s1/r1.play.mp3');
  });
}
