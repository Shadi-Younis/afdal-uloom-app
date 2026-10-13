import 'package:afdal_uloom_tilawat/core/models/picked_audio_file.dart';
import 'package:afdal_uloom_tilawat/core/services/audio_duration_reader.dart';

/// An [AudioDurationReader] that knows the lengths in [byName]; any other
/// file is unknown (null), as a format without length headers would be.
class FakeAudioDurationReader implements AudioDurationReader {
  final byName = <String, Duration>{};

  @override
  Future<Duration?> durationOf(PickedAudioFile file) async =>
      byName[file.name];
}
