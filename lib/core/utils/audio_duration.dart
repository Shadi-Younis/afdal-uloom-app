/// The length of an audio file from its headers, without decoding it: WAV
/// (RIFF), MP3 (the Xing / Info / VBRI frame count, else the constant
/// bitrate) and M4A (the movie header). Studio One exports WAV or MP3.
library;

import 'dart:typed_data';

/// The duration of the audio in [bytes] (the whole file) of type
/// [extension] (lower case, without the dot), or null when the format is
/// not one of those above or the headers cannot be read.
Duration? audioDurationOf(Uint8List bytes, String extension) {
  final data = ByteData.sublistView(bytes);
  final seconds = switch (extension) {
    'wav' => _wavSeconds(data),
    'mp3' => _mp3Seconds(data),
    'm4a' => _m4aSeconds(data),
    _ => null,
  };
  if (seconds == null || !seconds.isFinite || seconds <= 0) return null;
  return Duration(
    microseconds: (seconds * Duration.microsecondsPerSecond).round(),
  );
}

bool _tagAt(ByteData data, int offset, String tag) {
  if (offset < 0 || offset + tag.length > data.lengthInBytes) return false;
  for (var i = 0; i < tag.length; i++) {
    if (data.getUint8(offset + i) != tag.codeUnitAt(i)) return false;
  }
  return true;
}

/// RIFF: the `fmt ` chunk's byte rate and the `data` chunk's size.
double? _wavSeconds(ByteData data) {
  if (!_tagAt(data, 0, 'RIFF') || !_tagAt(data, 8, 'WAVE')) return null;
  int? byteRate;
  var offset = 12;
  while (offset + 8 <= data.lengthInBytes) {
    final size = data.getUint32(offset + 4, Endian.little);
    if (_tagAt(data, offset, 'fmt ') && offset + 16 <= data.lengthInBytes) {
      byteRate = data.getUint32(offset + 16, Endian.little);
    } else if (_tagAt(data, offset, 'data')) {
      if (byteRate == null || byteRate == 0) return null;
      final available = data.lengthInBytes - offset - 8;
      // A streamed WAV may say 0 or 0xFFFFFFFF: then the rest of the file.
      final length = size == 0 || size > available ? available : size;
      return length / byteRate;
    }
    // Chunks are padded to an even length.
    offset += 8 + size + (size.isOdd ? 1 : 0);
  }
  return null;
}

const _mpeg1Kbps = [
  0,
  32,
  40,
  48,
  56,
  64,
  80,
  96,
  112,
  128,
  160,
  192,
  224,
  256,
  320,
];
const _mpeg2Kbps = [
  0,
  8,
  16,
  24,
  32,
  40,
  48,
  56,
  64,
  80,
  96,
  112,
  128,
  144,
  160,
];
const _sampleRates = {
  3: [44100, 48000, 32000], // MPEG-1
  2: [22050, 24000, 16000], // MPEG-2
  0: [11025, 12000, 8000], // MPEG-2.5
};

/// The first Layer III frame after any ID3v2 tag: its frame count from a
/// Xing / Info / VBRI header, else the file's length at its bitrate.
double? _mp3Seconds(ByteData data) {
  var offset = 0;
  if (_tagAt(data, 0, 'ID3') && data.lengthInBytes >= 10) {
    // The size is four 7-bit bytes ("syncsafe"), without the 10-byte header.
    final size =
        (data.getUint8(6) << 21) |
        (data.getUint8(7) << 14) |
        (data.getUint8(8) << 7) |
        data.getUint8(9);
    offset = 10 + size + ((data.getUint8(5) & 0x10) != 0 ? 10 : 0);
  }
  // The first frame is near the start; give up after 64 KiB of garbage.
  final searchEnd = (offset + 65536).clamp(0, data.lengthInBytes - 4);
  for (; offset < searchEnd; offset++) {
    final frame = _frameAt(data, offset);
    if (frame == null) continue;
    final frames = _frameCount(data, offset, frame);
    if (frames != null) return frames * frame.samples / frame.sampleRate;
    var end = data.lengthInBytes;
    if (_tagAt(data, end - 128, 'TAG')) end -= 128; // ID3v1 at the end
    return (end - offset) * 8 / frame.bitrate;
  }
  return null;
}

typedef _Frame = ({
  int bitrate,
  int sampleRate,
  int samples,
  bool mpeg1,
  bool mono,
});

_Frame? _frameAt(ByteData data, int offset) {
  if (offset + 4 > data.lengthInBytes) return null;
  final b1 = data.getUint8(offset + 1);
  final b2 = data.getUint8(offset + 2);
  if (data.getUint8(offset) != 0xff || (b1 & 0xe0) != 0xe0) return null;
  final version = (b1 >> 3) & 0x03; // 3 = MPEG-1, 2 = MPEG-2, 0 = MPEG-2.5
  final layer = (b1 >> 1) & 0x03; // 1 = Layer III
  final bitrateIndex = b2 >> 4;
  final rateIndex = (b2 >> 2) & 0x03;
  if (version == 1 ||
      layer != 1 ||
      bitrateIndex == 0 ||
      bitrateIndex == 15 ||
      rateIndex == 3) {
    return null;
  }
  final mpeg1 = version == 3;
  return (
    bitrate: (mpeg1 ? _mpeg1Kbps : _mpeg2Kbps)[bitrateIndex] * 1000,
    sampleRate: _sampleRates[version]![rateIndex],
    samples: mpeg1 ? 1152 : 576,
    mpeg1: mpeg1,
    mono: (data.getUint8(offset + 3) >> 6) == 3,
  );
}

/// The number of frames a Xing / Info (LAME) or VBRI header gives.
int? _frameCount(ByteData data, int offset, _Frame frame) {
  final sideInfo = frame.mpeg1 ? (frame.mono ? 17 : 32) : (frame.mono ? 9 : 17);
  final xing = offset + 4 + sideInfo;
  if ((_tagAt(data, xing, 'Xing') || _tagAt(data, xing, 'Info')) &&
      xing + 12 <= data.lengthInBytes &&
      (data.getUint32(xing + 4) & 0x1) != 0) {
    return data.getUint32(xing + 8);
  }
  final vbri = offset + 4 + 32;
  if (_tagAt(data, vbri, 'VBRI') && vbri + 18 <= data.lengthInBytes) {
    return data.getUint32(vbri + 14);
  }
  return null;
}

/// MP4: the movie header (`mvhd`): its duration over its time scale.
double? _m4aSeconds(ByteData data) {
  for (var offset = 4; offset + 4 <= data.lengthInBytes; offset++) {
    if (!_tagAt(data, offset, 'mvhd')) continue;
    final body = offset + 4;
    if (body + 32 > data.lengthInBytes) return null;
    final version = data.getUint8(body);
    if (version == 1) {
      final scale = data.getUint32(body + 20);
      // Two halves: dart2js has no getUint64.
      final length =
          data.getUint32(body + 24) * 4294967296 + data.getUint32(body + 28);
      return scale == 0 ? null : length / scale;
    }
    final scale = data.getUint32(body + 12);
    final length = data.getUint32(body + 16);
    return scale == 0 ? null : length / scale;
  }
  return null;
}
