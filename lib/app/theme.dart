import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_sizes.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// The app's only theme (light), from the approved design
/// (docs/design/README.md): ivory pages, white cards with a gold hairline,
/// green buttons, Cairo for text, Amiri / Reem Kufi through
/// [AppTextStyles].
ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.green,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: AppColors.green,
        onPrimary: AppColors.onGreen,
        secondary: AppColors.goldDark,
        onSecondary: AppColors.onGreen,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.muted,
        surfaceTint: Colors.transparent,
        outline: AppColors.goldLight,
        outlineVariant: AppColors.goldLight,
        error: AppColors.error,
        primaryContainer: AppColors.greenTint,
        onPrimaryContainer: AppColors.green,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.ivory,
  );

  // Adjust the base styles (which carry colorScheme.onSurface) before applying
  // Cairo. Styles built from scratch with GoogleFonts.cairo() have no color,
  // which renders text white on the light background.
  final t = base.textTheme;
  final textTheme = GoogleFonts.cairoTextTheme(
    t.copyWith(
      headlineMedium: t.headlineMedium!.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: t.titleLarge!.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: t.titleMedium!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: t.bodyLarge!.copyWith(fontSize: 18),
      bodyMedium: t.bodyMedium!.copyWith(fontSize: 16),
      labelLarge: t.labelLarge!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  final styles = AppTextStyles.from(textTheme);

  const goldHairline = BorderSide(
    color: AppColors.goldLight,
    width: AppSizes.hairline,
  );
  RoundedRectangleBorder rounded(double radius, [BorderSide? side]) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side ?? BorderSide.none,
      );
  OutlineInputBorder field(Color color, [double width = AppSizes.hairline]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusField),
        borderSide: BorderSide(color: color, width: width),
      );
  final buttonText = textTheme.labelLarge;
  const buttonSize = Size.fromHeight(AppSizes.touchTarget);

  return base.copyWith(
    textTheme: textTheme,
    extensions: [styles],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.green,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: styles.heading,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 3,
      shadowColor: AppColors.greenTint,
      margin: EdgeInsets.zero,
      shape: rounded(AppSizes.radiusCard, goldHairline),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.onGreen,
        minimumSize: buttonSize,
        textStyle: buttonText,
        shape: rounded(AppSizes.radiusButton),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.green,
        minimumSize: buttonSize,
        textStyle: buttonText,
        side: goldHairline,
        shape: rounded(AppSizes.radiusButton),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.green,
        textStyle: buttonText,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.green,
      foregroundColor: AppColors.onGreen,
      extendedTextStyle: buttonText,
      shape: rounded(AppSizes.radiusCard),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.green,
      suffixIconColor: AppColors.muted,
      border: field(AppColors.goldLight),
      enabledBorder: field(AppColors.goldLight),
      disabledBorder: field(AppColors.goldLight),
      focusedBorder: field(AppColors.green, AppSizes.focusBorder),
      errorBorder: field(AppColors.error),
      focusedErrorBorder: field(AppColors.error, AppSizes.focusBorder),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppColors.greenTint,
      indicatorShape: rounded(AppSizes.radiusButton),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.green
              : AppColors.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium!.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.green
              : AppColors.muted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.greenTint,
      indicatorShape: rounded(AppSizes.radiusButton),
      selectedIconTheme: const IconThemeData(color: AppColors.green),
      unselectedIconTheme: const IconThemeData(color: AppColors.muted),
      selectedLabelTextStyle: textTheme.labelMedium!.copyWith(
        color: AppColors.green,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium!.copyWith(
        color: AppColors.muted,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.greenTint,
      side: goldHairline,
      labelStyle: textTheme.labelMedium!.copyWith(color: AppColors.ink),
      shape: rounded(AppSizes.radiusChip, goldHairline),
      checkmarkColor: AppColors.green,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      shape: rounded(AppSizes.radiusDialog, goldHairline),
      titleTextStyle: styles.heading,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusSheet),
        ),
        side: goldHairline,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.green,
      contentTextStyle: textTheme.bodyMedium!.copyWith(
        color: AppColors.onGreen,
      ),
      behavior: SnackBarBehavior.floating,
      shape: rounded(AppSizes.radiusSnackBar),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.green,
      inactiveTrackColor: AppColors.track,
      thumbColor: AppColors.gold,
      overlayColor: AppColors.goldTint,
      trackHeight: AppSizes.playerTrack,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(goldHairline),
        shape: WidgetStatePropertyAll(rounded(AppSizes.radiusButton)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.green
              : AppColors.card,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onGreen
              : AppColors.muted,
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.green,
      textColor: AppColors.ink,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.goldLight),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.green,
    ),
  );
}
