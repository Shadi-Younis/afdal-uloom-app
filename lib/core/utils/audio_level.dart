import '../constants/audio_formats.dart';

/// The level meter's 0..1 for a microphone level in dBFS (0 = loudest):
/// empty at AudioFormats.levelMeterFloorDb and below.
double meterLevelFromDb(double dbfs) {
  if (dbfs.isNaN) return 0;
  const floor = AudioFormats.levelMeterFloorDb;
  return ((dbfs - floor) / -floor).clamp(0.0, 1.0);
}
