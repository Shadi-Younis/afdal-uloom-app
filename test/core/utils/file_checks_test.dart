import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/utils/audio_file_check.dart';
import 'package:afdal_uloom_tilawat/core/utils/file_size.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_audio_file_picker.dart';

void main() {
  test('uploadProblemOf: accepted types under 100 MiB pass', () {
    expect(uploadProblemOf(pickedFile('a.mp3')), isNull);
    expect(uploadProblemOf(pickedFile('b.M4A')), isNull);
    expect(uploadProblemOf(pickedFile('c.webm')), isNull);
  });

  test('uploadProblemOf: another type, an empty file, too large', () {
    expect(uploadProblemOf(pickedFile('a.pdf')), AppErrorCode.unsupportedFile);
    expect(uploadProblemOf(pickedFile('noext')), AppErrorCode.unsupportedFile);
    expect(
      uploadProblemOf(pickedFile('a.mp3', sizeBytes: 0)),
      AppErrorCode.unsupportedFile,
    );
    expect(
      uploadProblemOf(pickedFile('a.mp3', sizeBytes: 100 * 1024 * 1024)),
      AppErrorCode.fileTooLarge,
    );
  });

  test('formatFileSize: megabytes, one decimal, Arabic digits', () {
    expect(formatFileSize(3 * 1024 * 1024), '٣٫٠ ميغابايت');
    expect(formatFileSize(1572864), '١٫٥ ميغابايت');
  });
}
