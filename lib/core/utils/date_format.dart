import 'package:intl/intl.dart';

import '../constants/app_strings.dart';

/// A day as "١٥ سبتمبر ٢٠٢٦". Needs the Arabic date symbols, which the
/// app's Material localizations load.
String formatDay(DateTime date) =>
    DateFormat.yMMMd(AppStrings.languageCode).format(date);
