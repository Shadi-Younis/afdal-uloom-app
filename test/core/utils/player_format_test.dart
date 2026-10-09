import 'package:afdal_uloom_tilawat/core/utils/player_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatClock: mm:ss in Arabic-Indic digits', () {
    expect(formatClock(Duration.zero), '٠٠:٠٠');
    expect(formatClock(const Duration(seconds: 83)), '٠١:٢٣');
    expect(formatClock(const Duration(minutes: 59, seconds: 59)), '٥٩:٥٩');
  });

  test('formatClock: hours from one hour on', () {
    expect(
      formatClock(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '١:٠٢:٠٣',
    );
  });

  test('formatSpeed', () {
    expect(formatSpeed(0.75), '٠٫٧٥×');
    expect(formatSpeed(1), '١×');
    expect(formatSpeed(1.25), '١٫٢٥×');
  });
}
