import 'dart:math';

import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/halaqa.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/password_generator_provider.dart';
import 'package:afdal_uloom_tilawat/core/providers/repository_providers.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/core/utils/password_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fake_accounts_service.dart';
import 'fake_auth_service.dart';
import 'fake_halaqa_repository.dart';
import 'fake_user_repository.dart';

const adminSession = AuthSession(uid: 'shadi', role: UserRole.admin);

/// A small school like the seed's: admin shadi; teachers t01 (حلقة الفجر)
/// and t02 (حلقة العصر), t03 disabled; students s001, s002 in الفجر, s003
/// in العصر, s012 in الفجر and disabled.
class AdminFixture {
  AdminFixture()
    : users = FakeUserRepository({
        'shadi': seedUser('shadi', 'شادي', UserRole.admin),
        't01': seedUser('t01', 'الشيخ محمود', UserRole.teacher),
        't02': seedUser('t02', 'الشيخ عبد الرحمن', UserRole.teacher),
        't03': seedUser(
          't03',
          'الشيخ سعيد',
          UserRole.teacher,
        ).copyWith(disabled: true),
        's001': seedStudent('s001', 'أحمد الخطيب', 'halaqa-fajr'),
        's002': seedStudent('s002', 'عمر الحسن', 'halaqa-fajr'),
        's003': seedStudent('s003', 'يوسف النجار', 'halaqa-asr'),
        's012': seedStudent('s012', 'أنس جابر', 'halaqa-fajr', disabled: true),
      }),
      halaqat = FakeHalaqaRepository(const [
        Halaqa(id: 'halaqa-fajr', name: 'حلقة الفجر', teacherId: 't01'),
        Halaqa(id: 'halaqa-asr', name: 'حلقة العصر', teacherId: 't02'),
      ]) {
    accounts = FakeAccountsService(users: users, halaqat: halaqat);
  }

  /// No halaqat, teachers or students: only the admin.
  AdminFixture.empty()
    : users = FakeUserRepository({
        'shadi': seedUser('shadi', 'شادي', UserRole.admin),
      }),
      halaqat = FakeHalaqaRepository() {
    accounts = FakeAccountsService(users: users, halaqat: halaqat);
  }

  final FakeUserRepository users;
  final FakeHalaqaRepository halaqat;
  late final FakeAccountsService accounts;
  final auth = FakeAuthService(initial: adminSession);

  /// The same passwords in every run.
  PasswordGenerator get passwords => PasswordGenerator(Random(1));

  List<Override> get overrides => [
    authServiceProvider.overrideWithValue(auth),
    userRepositoryProvider.overrideWithValue(users),
    halaqaRepositoryProvider.overrideWithValue(halaqat),
    accountsServiceProvider.overrideWithValue(accounts),
    passwordGeneratorProvider.overrideWith((ref) => passwords),
  ];

  /// A container on the fakes, disposed after the test.
  ProviderContainer container() => ProviderContainer.test(overrides: overrides);
}
