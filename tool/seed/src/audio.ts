// Stand-ins for recitations, generated here (no downloads): 16 kHz mono
// 16-bit WAV files of short melodic phrases separated by pauses, so that
// playing, seeking and the position are easy to hear and see.

const SAMPLE_RATE = 16000;

export interface Tone {
  name: string;
  seconds: number;
  wav: Buffer;
}

/** Three different stand-ins: 20, 30 and 40 seconds. */
export function makeTones(): Tone[] {
  return [
    { name: "tone-a", seconds: 20, wav: phrases(20, 220, [0, 2, 4, 2, 0, -1]) },
    { name: "tone-b", seconds: 30, wav: phrases(30, 247, [0, 3, 5, 3, 2, 0, -2]) },
    { name: "tone-c", seconds: 40, wav: phrases(40, 196, [0, 4, 7, 4, 5, 2, 0]) },
  ];
}

/**
 * [seconds] of phrases: each phrase sings the [steps] (semitones above
 * [baseHz]) for 3 s, then 1 s of silence. A soft envelope avoids clicks.
 */
function phrases(seconds: number, baseHz: number, steps: number[]): Buffer {
  const total = seconds * SAMPLE_RATE;
  const samples = new Int16Array(total);
  const phrase = 4 * SAMPLE_RATE;
  const sung = 3 * SAMPLE_RATE;
  const noteLength = Math.floor(sung / steps.length);
  let phase = 0;
  for (let i = 0; i < total; i++) {
    const inPhrase = i % phrase;
    if (inPhrase >= sung) continue; // the pause between phrases
    const note = Math.min(Math.floor(inPhrase / noteLength), steps.length - 1);
    // Each phrase starts a little higher, like a reciter's rising voice.
    const lift = Math.floor(i / phrase) % 3;
    const hz = baseHz * 2 ** ((steps[note] + lift) / 12);
    phase += (2 * Math.PI * hz) / SAMPLE_RATE;
    const inNote = (inPhrase % noteLength) / noteLength;
    const envelope = Math.min(1, inNote * 20) * Math.min(1, (1 - inNote) * 20);
    // A fundamental and a softer octave: warmer than a pure sine.
    const value = Math.sin(phase) * 0.7 + Math.sin(2 * phase) * 0.2;
    samples[i] = Math.round(value * envelope * 0.5 * 32767);
  }
  return wavFile(samples);
}

function wavFile(samples: Int16Array): Buffer {
  const dataBytes = samples.length * 2;
  const header = Buffer.alloc(44);
  header.write("RIFF", 0);
  header.writeUInt32LE(36 + dataBytes, 4);
  header.write("WAVE", 8);
  header.write("fmt ", 12);
  header.writeUInt32LE(16, 16); // PCM chunk size
  header.writeUInt16LE(1, 20); // PCM
  header.writeUInt16LE(1, 22); // mono
  header.writeUInt32LE(SAMPLE_RATE, 24);
  header.writeUInt32LE(SAMPLE_RATE * 2, 28); // bytes per second
  header.writeUInt16LE(2, 32); // bytes per sample
  header.writeUInt16LE(16, 34); // bits per sample
  header.write("data", 36);
  header.writeUInt32LE(dataBytes, 40);
  return Buffer.concat([header, Buffer.from(samples.buffer)]);
}
