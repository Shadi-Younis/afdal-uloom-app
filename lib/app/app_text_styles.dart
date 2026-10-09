import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The named text styles of the design, beyond Material's text theme:
/// Amiri for Quranic and ornamental text, Reem Kufi for headings and big
/// numbers. Body text, fields and buttons stay Cairo (the text theme).
///
/// Registered in the theme (buildAppTheme); read with
/// `AppTextStyles.of(context).basmala`.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.basmala,
    required this.hadith,
    required this.salam,
    required this.surahTitle,
    required this.heading,
    required this.headerName,
    required this.sectionTitle,
    required this.statNumber,
  });

  /// Built from [base] (the theme's text theme) so sizes and colors are
  /// those of the design.
  factory AppTextStyles.from(TextTheme base) {
    final body = base.bodyLarge!;
    TextStyle amiri(double size, Color color, [FontWeight? weight]) =>
        GoogleFonts.amiri(
          textStyle: body.copyWith(
            fontSize: size,
            color: color,
            fontWeight: weight ?? FontWeight.w400,
            height: 1.5,
          ),
        );
    TextStyle kufi(double size, Color color) => GoogleFonts.reemKufi(
      textStyle: body.copyWith(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
    return AppTextStyles(
      basmala: amiri(26, AppColors.green),
      hadith: amiri(17, AppColors.goldDark),
      salam: amiri(20, AppColors.goldLight),
      surahTitle: amiri(28, AppColors.onGreen, FontWeight.w700),
      heading: kufi(20, AppColors.green),
      headerName: kufi(30, AppColors.onGreen),
      sectionTitle: kufi(17, AppColors.green),
      statNumber: kufi(26, AppColors.green),
    );
  }

  /// "بسم الله الرحمن الرحيم" at the top of the login screen.
  final TextStyle basmala;

  /// The hadith under the logo (gold text that is readable on ivory).
  final TextStyle hadith;

  /// The greeting in the green header.
  final TextStyle salam;

  /// The surah name in its cartouche.
  final TextStyle surahTitle;

  /// Page and dialog titles.
  final TextStyle heading;

  /// The user's name in the green header.
  final TextStyle headerName;

  /// Titles between ornament lines (OrnamentDivider).
  final TextStyle sectionTitle;

  /// The big numbers of the home screen's stat cards.
  final TextStyle statNumber;

  static AppTextStyles of(BuildContext context) =>
      Theme.of(context).extension<AppTextStyles>()!;

  @override
  AppTextStyles copyWith({
    TextStyle? basmala,
    TextStyle? hadith,
    TextStyle? salam,
    TextStyle? surahTitle,
    TextStyle? heading,
    TextStyle? headerName,
    TextStyle? sectionTitle,
    TextStyle? statNumber,
  }) => AppTextStyles(
    basmala: basmala ?? this.basmala,
    hadith: hadith ?? this.hadith,
    salam: salam ?? this.salam,
    surahTitle: surahTitle ?? this.surahTitle,
    heading: heading ?? this.heading,
    headerName: headerName ?? this.headerName,
    sectionTitle: sectionTitle ?? this.sectionTitle,
    statNumber: statNumber ?? this.statNumber,
  );

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTextStyles(
      basmala: mix(basmala, other.basmala),
      hadith: mix(hadith, other.hadith),
      salam: mix(salam, other.salam),
      surahTitle: mix(surahTitle, other.surahTitle),
      heading: mix(heading, other.heading),
      headerName: mix(headerName, other.headerName),
      sectionTitle: mix(sectionTitle, other.sectionTitle),
      statNumber: mix(statNumber, other.statNumber),
    );
  }
}
