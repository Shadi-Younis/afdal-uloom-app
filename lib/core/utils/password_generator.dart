import 'dart:math';

import '../constants/model_limits.dart';

/// Generates initial and reset passwords that are easy to read aloud and
/// type on a phone: [ModelLimits.generatedPasswordLength] lower-case
/// letters and digits without look-alikes, at least
/// [ModelLimits.generatedPasswordMinDigits] of them digits.
class PasswordGenerator {
  /// [random] is for tests; the default is cryptographically secure.
  PasswordGenerator([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  String generate() {
    const digits = ModelLimits.generatedPasswordDigits;
    const all = ModelLimits.generatedPasswordLetters + digits;
    final chars = [
      for (var i = 0; i < ModelLimits.generatedPasswordMinDigits; i++)
        _pick(digits),
      for (
        var i = ModelLimits.generatedPasswordMinDigits;
        i < ModelLimits.generatedPasswordLength;
        i++
      )
        _pick(all),
    ]..shuffle(_random);
    return chars.join();
  }

  String _pick(String from) => from[_random.nextInt(from.length)];
}
