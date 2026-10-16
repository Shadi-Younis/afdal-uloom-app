// The whole analysis of one stereo file on disk: decode, the mono check,
// then where the sheikh spoke. Shared by onRecordingUploaded and the local
// tool (tool/analyse_audio), so both always give the same answer.
import {decodeLevels} from "./ffmpeg.js";
import {analyseVoices, isMonoLike, type VoiceAnalysis} from "./voice_analysis.js";

export interface FileAnalysis {
  durationSeconds: number;
  /** Null when the file is mono-like: there is no separate sheikh channel. */
  voices: VoiceAnalysis | null;
}

/** Analyses the stereo file at [path]; throws AudioToolError when it cannot be decoded. */
export async function analyseFile(path: string): Promise<FileAnalysis> {
  const {levels, durationSeconds} = await decodeLevels(path);
  return {durationSeconds, voices: isMonoLike(levels) ? null : analyseVoices(levels)};
}
