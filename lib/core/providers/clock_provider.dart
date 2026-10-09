import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time. Tests override it to fix "today" (e.g. the Hijri date
/// in the home header).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
