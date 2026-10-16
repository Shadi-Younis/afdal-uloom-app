import 'dart:typed_data';

import 'package:afdal_uloom_tilawat/core/utils/audio_duration.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bytes from a list of chunks: strings as ASCII, ints as single bytes.
Uint8List bytesOf(List<Object> parts) {
  final builder = BytesBuilder();
  for (final part in parts) {
    switch (part) {
      case String text:
        builder.add(text.codeUnits);
      case int byte:
        builder.addByte(byte);
      case List<int> list:
        builder.add(list);
    }
  }
  return builder.toBytes();
}

List<int> le32(int value) =>
    (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();
List<int> le16(int value) =>
    (ByteData(2)..setUint16(0, value, Endian.little)).buffer.asUint8List();
List<int> be32(int value) =>
    (ByteData(4)..setUint32(0, value)).buffer.asUint8List();

/// A PCM WAV: [seconds] of 16-bit stereo at 44.1 kHz.
Uint8List wav(double seconds, {int? declaredSize, bool extraChunk = false}) {
  const byteRate = 44100 * 2 * 2;
  final dataSize = (seconds * byteRate).round();
  return bytesOf([
    'RIFF', le32(36 + dataSize), 'WAVE',
    'fmt ', le32(16), le16(1), le16(2), le32(44100), le32(byteRate), le16(4), le16(16),
    if (extraChunk) ...['LIST', le32(3), 'abc', 0], // odd size: one pad byte
    'data', le32(declaredSize ?? dataSize), List<int>.filled(dataSize, 0),
  ]);
}

/// An MP3: one MPEG-1 Layer III frame header (128 kbit/s, 44.1 kHz,
/// stereo), optionally with a LAME Info tag of [frames] frames, then
/// [bodyBytes] of audio.
Uint8List mp3({int? frames, int bodyBytes = 0, bool id3 = false}) {
  final header = [0xff, 0xfb, 0x90, 0x00];
  return bytesOf([
    if (id3) ...['ID3', 4, 0, 0, 0, 0, 0, 10, List<int>.filled(10, 0)],
    header,
    List<int>.filled(32, 0), // side information
    if (frames != null) ...['Info', be32(0x1), be32(frames)],
    List<int>.filled(bodyBytes, 0),
  ]);
}

void main() {
  test('WAV: the data chunk over the byte rate', () {
    expect(audioDurationOf(wav(1.5), 'wav'), const Duration(milliseconds: 1500));
    expect(
      audioDurationOf(wav(2, extraChunk: true), 'wav'),
      const Duration(seconds: 2),
    );
    // Streamed: no size, the rest of the file.
    expect(
      audioDurationOf(wav(0.5, declaredSize: 0xffffffff), 'wav'),
      const Duration(milliseconds: 500),
    );
  });

  test('MP3: the Info frame count', () {
    // 2297 frames of 1152 samples at 44.1 kHz = 60.0 s.
    final duration = audioDurationOf(mp3(frames: 2297, id3: true), 'mp3')!;
    expect(duration.inMilliseconds, closeTo(60003, 2));
  });

  test('MP3 without a frame count: its length at its bitrate', () {
    // 16000 bytes at 128 kbit/s = 1 s.
    final bytes = mp3(bodyBytes: 16000 - 36);
    expect(audioDurationOf(bytes, 'mp3'), const Duration(seconds: 1));
  });

  test('M4A: the movie header', () {
    final bytes = bytesOf([
      le32(0), 'ftyp', 'M4A ',
      be32(108), 'moov', be32(100), 'mvhd',
      0, 0, 0, 0, // version 0, flags
      be32(0), be32(0), // created, modified
      be32(1000), be32(61500), // time scale, duration
      List<int>.filled(80, 0),
    ]);
    expect(audioDurationOf(bytes, 'm4a'), const Duration(milliseconds: 61500));
  });

  test('unknown formats and broken headers: null', () {
    expect(audioDurationOf(wav(1), 'ogg'), isNull);
    expect(audioDurationOf(Uint8List(0), 'wav'), isNull);
    expect(audioDurationOf(bytesOf(['RIFF', le32(4), 'WAVE']), 'wav'), isNull);
    expect(audioDurationOf(Uint8List.fromList(List.filled(100, 7)), 'mp3'), isNull);
    expect(audioDurationOf(bytesOf(['nothing here']), 'm4a'), isNull);
  });
}
