import 'package:afdal_uloom_tilawat/core/utils/parsed_recording_name.dart';
import 'package:afdal_uloom_tilawat/core/utils/recording_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ParsedRecordingName parse(String name) => parseRecordingFileName(name);

  test('S014_002_001-020.mp3: code, surah, ayat', () {
    expect(
      parse('S014_002_001-020.mp3'),
      const ParsedRecordingName(
        studentCode: 'S014',
        surahNumber: 2,
        ayahFrom: 1,
        ayahTo: 20,
      ),
    );
  });

  test('without leading zeros, any extension or case', () {
    const expected = ParsedRecordingName(
      studentCode: 'S014',
      surahNumber: 2,
      ayahFrom: 1,
      ayahTo: 20,
    );
    expect(parse('S014_2_1-20.mp3'), expected);
    expect(parse('s014_2_1-20.WAV'), expected);
    expect(parse('S014_2_1-20'), expected);
  });

  test('with the recording date of the plan (S023_2026-10-05_002_1-20)', () {
    expect(
      parse('S023_2026-10-05_002_1-20.mp3'),
      ParsedRecordingName(
        studentCode: 'S023',
        surahNumber: 2,
        ayahFrom: 1,
        ayahTo: 20,
        recordedAt: DateTime(2026, 10, 5),
      ),
    );
  });

  test('one ayah alone', () {
    expect(
      parse('S014_067_5.mp3'),
      const ParsedRecordingName(
        studentCode: 'S014',
        surahNumber: 67,
        ayahFrom: 5,
        ayahTo: 5,
      ),
    );
  });

  test('five-digit codes, as the server accepts', () {
    expect(parse('S12345_1_1-7.mp3').studentCode, 'S12345');
  });

  test('ayat outside the surah: surah kept, ayat left empty', () {
    expect(
      parse('S014_001_1-8.mp3'),
      const ParsedRecordingName(studentCode: 'S014', surahNumber: 1),
    );
    expect(parse('S014_001_5-3.mp3').ayahFrom, isNull);
    expect(parse('S014_001_0-3.mp3').ayahFrom, isNull);
  });

  test('a surah that does not exist: surah and ayat empty', () {
    expect(
      parse('S014_115_1-3.mp3'),
      const ParsedRecordingName(studentCode: 'S014'),
    );
    expect(parse('S014_0_1-3.mp3').surahNumber, isNull);
  });

  test('a day that does not exist is ignored, the rest still read', () {
    final parsed = parse('S014_2026-02-30_002_1-5.mp3');
    expect(parsed.recordedAt, isNull);
    expect(parsed.surahNumber, 2);
    expect(parsed.ayahTo, 5);
  });

  test('names that are not in the studio form give nothing', () {
    const nothing = ParsedRecordingName();
    expect(parse('تلاوة أحمد.mp3'), nothing);
    expect(parse('Mixdown(1).wav'), nothing);
    expect(parse('.mp3'), nothing);
    expect(parse('X014_002_1-20.mp3'), nothing);
    expect(parse('S01_002_1-20.mp3').studentCode, isNull);
  });

  test('a stem: the track name after the ayat is ignored (Task 11)', () {
    const expected = ParsedRecordingName(
      studentCode: 'S014',
      surahNumber: 2,
      ayahFrom: 1,
      ayahTo: 20,
    );
    expect(parse('S014_002_001-020 - Student.wav'), expected);
    expect(parse('S014_002_001-020 - الشيخ.mp3'), expected);
    expect(parse('S014_002_001-020_sheikh.wav'), expected);
    expect(parse('S014_002_001-020.student.wav'), expected);
    // Still digits: not ayat.
    expect(parse('S014_002_001-0200.mp3').ayahFrom, isNull);
    expect(parse('S014_002_001--20.mp3').ayahFrom, isNull);
  });

  test('only the code (Task 12): the student alone, no surah or ayat', () {
    const student = ParsedRecordingName(studentCode: 'S014');
    expect(parse('S014.mp3'), student);
    expect(parse('s014.wav'), student);
    expect(parse('S014_take2.wav'), student);
    expect(parse('S014 - Student.wav'), student);
    expect(parse('S014.student.wav'), student);
    expect(parse('S014-final.m4a'), student);
    // Still a longer code or a word, not a code and a label.
    expect(parse('S0145678.mp3'), const ParsedRecordingName());
    expect(parse('S014abc.mp3'), const ParsedRecordingName());
  });

  test('the code and a surah without ayat', () {
    expect(
      parse('S014_002.mp3'),
      const ParsedRecordingName(studentCode: 'S014', surahNumber: 2),
    );
  });

  test('a name without a code still gives the surah and ayat', () {
    expect(
      parse('002_1-20.mp3'),
      const ParsedRecordingName(surahNumber: 2, ayahFrom: 1, ayahTo: 20),
    );
  });
}
