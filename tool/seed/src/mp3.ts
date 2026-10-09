// Reads an MP3 file's duration by walking its frames, so the seeded
// durationSec matches what the player shows. Works for CBR and VBR files.

// Bitrates in kbit/s by [index], for MPEG-1 Layer III and MPEG-2/2.5 Layer III.
const MPEG1_KBPS = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320];
const MPEG2_KBPS = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160];
const SAMPLE_RATES: Record<number, number[]> = {
  3: [44100, 48000, 32000], // MPEG-1
  2: [22050, 24000, 16000], // MPEG-2
  0: [11025, 12000, 8000], // MPEG-2.5
};

/** The duration of the MP3 in [file], in seconds; throws if it has no Layer III frames. */
export function mp3DurationSeconds(file: Buffer): number {
  let offset = skipId3v2(file);
  let seconds = 0;
  let frames = 0;
  while (offset + 4 <= file.length) {
    const frame = parseFrameHeader(file, offset);
    if (frame === null) {
      // Trailing tags or padding end the audio once we have seen frames.
      if (frames > 0) break;
      offset++;
      continue;
    }
    seconds += frame.samples / frame.sampleRate;
    frames++;
    offset += frame.length;
  }
  if (frames === 0) throw new Error("not an MP3 (Layer III) file");
  return seconds;
}

function skipId3v2(file: Buffer): number {
  if (file.length < 10 || file.toString("latin1", 0, 3) !== "ID3") return 0;
  // The size is four 7-bit bytes ("syncsafe"), excluding the 10-byte header.
  const size = (file[6] << 21) | (file[7] << 14) | (file[8] << 7) | file[9];
  const hasFooter = (file[5] & 0x10) !== 0;
  return 10 + size + (hasFooter ? 10 : 0);
}

interface Frame {
  length: number;
  samples: number;
  sampleRate: number;
}

function parseFrameHeader(file: Buffer, offset: number): Frame | null {
  const b1 = file[offset + 1];
  const b2 = file[offset + 2];
  if (file[offset] !== 0xff || (b1 & 0xe0) !== 0xe0) return null;
  const version = (b1 >> 3) & 0x03; // 3 = MPEG-1, 2 = MPEG-2, 0 = MPEG-2.5
  const layer = (b1 >> 1) & 0x03; // 1 = Layer III
  const bitrateIndex = b2 >> 4;
  const rateIndex = (b2 >> 2) & 0x03;
  if (version === 1 || layer !== 1 || bitrateIndex === 0 || bitrateIndex === 15 || rateIndex === 3) {
    return null;
  }
  const mpeg1 = version === 3;
  const bitrate = (mpeg1 ? MPEG1_KBPS : MPEG2_KBPS)[bitrateIndex] * 1000;
  const sampleRate = SAMPLE_RATES[version][rateIndex];
  const padding = (b2 >> 1) & 0x01;
  const samples = mpeg1 ? 1152 : 576;
  const length = Math.floor((samples / 8) * bitrate / sampleRate) + padding;
  return { length, samples, sampleRate };
}
