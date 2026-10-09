import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/recording_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_audio_player_service.dart';
import '../../../helpers/fake_audio_storage_service.dart';
import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  const path = 'recordings/s001/rec-02.wav';
  late FakeAudioPlayerService player;
  late FakeAudioStorageService storage;

  setUp(() {
    player = FakeAudioPlayerService();
    storage = FakeAudioStorageService();
  });

  Future<void> pumpPlayer(WidgetTester tester) => pumpScreen(
    tester,
    const Scaffold(
      body: SingleChildScrollView(child: RecordingPlayer(storagePath: path)),
    ),
    auth: FakeAuthService(),
    overrides: [
      audioPlayerServiceProvider.overrideWith((ref) {
        ref.onDispose(player.dispose);
        return player;
      }),
      audioStorageServiceProvider.overrideWithValue(storage),
    ],
  );

  testWidgets('loading: a spinner and Arabic text', (tester) async {
    player.loadGate = Completer<void>();
    await pumpPlayer(tester);
    await tester.pump();
    expect(find.text('جارٍ تحميل التسجيل'), findsOneWidget);
    player.loadGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('جارٍ تحميل التسجيل'), findsNothing);
  });

  testWidgets('ready on a phone: times, controls and speeds, no overflow', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpPlayer(tester);
    await tester.pumpAndSettle();

    expect(find.text('٠٠:٠٠'), findsOneWidget);
    expect(find.text('٠٠:٣٠'), findsOneWidget);
    expect(find.byTooltip('تشغيل'), findsOneWidget);
    expect(find.byTooltip('رجوع ٥ ثوانٍ'), findsOneWidget);
    expect(find.byTooltip('تقديم ٥ ثوانٍ'), findsOneWidget);
    for (final label in ['٠٫٧٥×', '١×', '١٫٢٥×']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);

    // Touch targets of at least 48 x 48.
    for (final tooltip in ['تشغيل', 'رجوع ٥ ثوانٍ', 'تقديم ٥ ثوانٍ']) {
      final size = tester.getSize(find.byTooltip(tooltip));
      expect(size.width, greaterThanOrEqualTo(48), reason: tooltip);
      expect(size.height, greaterThanOrEqualTo(48), reason: tooltip);
    }
    expect(
      tester.getSize(find.byType(SegmentedButton<double>)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('RTL: back 5 s on the right, forward 5 s on the left', (
    tester,
  ) async {
    await pumpPlayer(tester);
    await tester.pumpAndSettle();
    final back = tester.getCenter(find.byTooltip('رجوع ٥ ثوانٍ'));
    final forward = tester.getCenter(find.byTooltip('تقديم ٥ ثوانٍ'));
    expect(back.dx, greaterThan(forward.dx));
    // The current time at the start (right), the total at the end (left).
    expect(
      tester.getCenter(find.text('٠٠:٠٠')).dx,
      greaterThan(tester.getCenter(find.text('٠٠:٣٠')).dx),
    );
  });

  testWidgets('play, skip forward, speed 1.25', (tester) async {
    await pumpPlayer(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('تشغيل'));
    await tester.pump();
    expect(player.playCalls, 1);
    expect(find.byTooltip('إيقاف مؤقت'), findsOneWidget);

    await tester.tap(find.byTooltip('تقديم ٥ ثوانٍ'));
    await tester.pump();
    expect(player.seeks, [const Duration(seconds: 5)]);
    expect(find.text('٠٠:٠٥'), findsOneWidget);

    await tester.tap(find.text('١٫٢٥×'));
    await tester.pump();
    expect(player.speeds, [1.25]);
  });

  testWidgets('error: Arabic message and a retry that loads again', (
    tester,
  ) async {
    storage.urlError = const AppException(AppErrorCode.permissionDenied);
    await pumpPlayer(tester);
    await tester.pumpAndSettle();
    expect(find.text('ليست لديك صلاحية لهذا الإجراء.'), findsOneWidget);

    storage.urlError = null;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('تشغيل'), findsOneWidget);
  });

  testWidgets('removed from the screen: the player is disposed', (
    tester,
  ) async {
    await pumpPlayer(tester);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(player.disposed, isTrue);
  });
}
