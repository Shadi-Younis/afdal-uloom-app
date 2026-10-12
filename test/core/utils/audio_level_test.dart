import 'package:afdal_uloom_tilawat/core/utils/audio_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the meter: empty at -50 dBFS and below, full at 0', () {
    expect(meterLevelFromDb(-160), 0);
    expect(meterLevelFromDb(-50), 0);
    expect(meterLevelFromDb(-25), closeTo(0.5, 1e-9));
    expect(meterLevelFromDb(0), 1);
    expect(meterLevelFromDb(3), 1);
    expect(meterLevelFromDb(double.nan), 0);
  });
}
