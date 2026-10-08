import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/utils/error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every code has its own Arabic message', () {
    final messages = AppErrorCode.values.map(errorMessageFor).toList();
    expect(messages.toSet(), hasLength(AppErrorCode.values.length));
    for (final message in messages) {
      expect(message, matches(RegExp('[؀-ۿ]')));
    }
  });

  test('permission denied message', () {
    expect(
      errorMessageFor(AppErrorCode.permissionDenied),
      'ليست لديك صلاحية لهذا الإجراء.',
    );
  });
}
