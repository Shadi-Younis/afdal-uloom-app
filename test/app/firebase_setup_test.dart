import 'package:afdal_uloom_tilawat/app/firebase_setup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('functions run in me-west1', () {
    expect(kFunctionsRegion, 'me-west1');
  });

  test('emulators are off unless USE_EMULATORS=true is passed', () {
    expect(useEmulators, isFalse);
  });

  group('resolveEmulatorHost', () {
    test('web uses localhost', () {
      expect(
        resolveEmulatorHost(isWeb: true, platform: TargetPlatform.android),
        'localhost',
      );
    });

    test('Android emulator uses 10.0.2.2', () {
      expect(
        resolveEmulatorHost(isWeb: false, platform: TargetPlatform.android),
        '10.0.2.2',
      );
    });

    test('iOS simulator uses localhost', () {
      expect(
        resolveEmulatorHost(isWeb: false, platform: TargetPlatform.iOS),
        'localhost',
      );
    });

    test('EMULATOR_HOST overrides the default', () {
      expect(
        resolveEmulatorHost(
          isWeb: false,
          platform: TargetPlatform.android,
          override: '192.168.1.50',
        ),
        '192.168.1.50',
      );
    });
  });
}
