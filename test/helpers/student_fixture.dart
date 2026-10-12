import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/clock_provider.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'admin_fixture.dart';
import 'fake_audio_file_picker.dart';
import 'fake_audio_recorder_service.dart';

const studentSession = AuthSession(uid: 's001', role: UserRole.student);

/// [AdminFixture]'s school signed in as the student s001 (أحمد الخطيب,
/// حلقة الفجر of t01 «الشيخ محمود», whose teacherName is known), with a
/// recorder and a file picker without hardware, on Monday 2026-10-12 (the
/// school week began on Saturday 2026-10-10).
class StudentFixture {
  StudentFixture() {
    school.auth.emit(studentSession);
    final fajr = school.halaqat.halaqat['halaqa-fajr']!;
    school.halaqat.put(fajr.copyWith(teacherName: 'الشيخ محمود'));
  }

  final school = AdminFixture();
  final recorder = FakeAudioRecorderService();
  final picker = FakeAudioFilePicker();
  DateTime now = DateTime(2026, 10, 12, 17);

  List<Override> get overrides => [
    ...school.overrides,
    audioRecorderServiceProvider.overrideWith((ref) => recorder),
    audioFilePickerProvider.overrideWithValue(picker),
    clockProvider.overrideWithValue(() => now),
  ];

  /// A container on the fakes, disposed after the test.
  ProviderContainer container() => ProviderContainer.test(overrides: overrides);
}
