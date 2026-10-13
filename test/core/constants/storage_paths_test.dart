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

  test('the two files of a two-file recording sit next to it', () {
    expect(
      StoragePaths.stem('s1', 'r1', StoragePaths.stemStudent, extension: 'wav'),
      'recordings/s1/r1.student.wav',
    );
    expect(
      StoragePaths.stem('s1', 'r1', StoragePaths.stemSheikh, extension: 'mp3'),
      'recordings/s1/r1.sheikh.mp3',
    );
  });

  test('the playback copy sits next to the recording', () {
    expect(StoragePaths.playback('s1', 'r1'), 'recordings/s1/r1.play.mp3');
  });
}
