import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rpg_colors.dart';
import 'rpg_spacing.dart';
import 'rpg_text_styles.dart';

/// App-wide theme configuration for DailyFlow 2.0.
/// Implements the Enchanted Twilight Fantasy aesthetic across Dark & Light modes.
class AppTheme {
  static const primaryColor = RpgColors.rpgIndigo;
  static const lightScaffoldColor = RpgColors.rpgMist;
  static const darkScaffoldColor = RpgColors.rpgAbyss;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: RpgColors.rpgIndigo,
      secondary: RpgColors.rpgViolet,
      tertiary: RpgColors.rpgGold,
      surface: RpgColors.rpgSurfaceLight,
      surfaceContainer: RpgColors.rpgSurfaceLightAlt,
      outline: RpgColors.rpgBorderLight,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightScaffoldColor,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: RpgColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: RpgColors.rpgIndigo,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: RpgColors.textSecondaryLight,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: RpgColors.rpgSurfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusCard),
          side: const BorderSide(color: RpgColors.rpgBorderLight, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: RpgColors.rpgSurfaceLight,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusLarge),
          side: const BorderSide(color: RpgColors.rpgBorderLight),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RpgColors.rpgSurfaceLight,
        modalBackgroundColor: RpgColors.rpgSurfaceLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RpgSpacing.radiusLarge),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RpgColors.rpgSurfaceLightAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RpgSpacing.lg,
          vertical: RpgSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusMedium),
          borderSide: const BorderSide(color: RpgColors.rpgBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusMedium),
          borderSide: const BorderSide(color: RpgColors.rpgBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusMedium),
          borderSide: const BorderSide(color: RpgColors.rpgViolet, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
        ),
        side: const BorderSide(color: RpgColors.rpgBorderLight),
      ),
      dividerTheme: const DividerThemeData(
        color: RpgColors.rpgBorderLight,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: RpgTextStyles.displayLarge,
        headlineLarge: RpgTextStyles.headlineLarge,
        headlineMedium: RpgTextStyles.headlineMedium,
        titleLarge: RpgTextStyles.titleLarge,
        titleMedium: RpgTextStyles.titleMedium,
        titleSmall: RpgTextStyles.titleSmall,
        bodyLarge: RpgTextStyles.bodyLarge,
        bodyMedium: RpgTextStyles.bodyMedium,
        bodySmall: RpgTextStyles.bodySmall,
        labelLarge: RpgTextStyles.labelLarge,
        labelMedium: RpgTextStyles.labelMedium,
        labelSmall: RpgTextStyles.labelSmall,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: RpgColors.rpgIndigo,
      secondary: RpgColors.rpgViolet,
      tertiary: RpgColors.rpgGold,
      surface: RpgColors.rpgSurfaceDark,
      surfaceContainer: RpgColors.rpgSurfaceElevated,
      outline: RpgColors.rpgBorderDark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkScaffoldColor,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: RpgColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: RpgColors.rpgSurfaceDark,
        elevation: 3,
        indicatorColor: primaryColor.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: RpgColors.rpgVioletLight,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: RpgColors.textSecondaryDark,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: RpgColors.rpgSurfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusCard),
          side: const BorderSide(color: RpgColors.rpgBorderDark, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: RpgColors.rpgSurfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusLarge),
          side: const BorderSide(color: RpgColors.rpgBorderDark),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RpgColors.rpgSurfaceDark,
        modalBackgroundColor: RpgColors.rpgSurfaceDark,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RpgSpacing.radiusLarge),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RpgColors.rpgDungeonSlate,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RpgSpacing.lg,
          vertical: RpgSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusMedium),
          borderSide: const BorderSide(color: RpgColors.rpgBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusMedium),
          borderSide: const BorderSide(color: RpgColors.rpgBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusMedium),
          borderSide: const BorderSide(color: RpgColors.rpgViolet, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
        ),
        side: const BorderSide(color: RpgColors.rpgBorderDark),
      ),
      dividerTheme: const DividerThemeData(
        color: RpgColors.rpgBorderDark,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: RpgTextStyles.displayLarge,
        headlineLarge: RpgTextStyles.headlineLarge,
        headlineMedium: RpgTextStyles.headlineMedium,
        titleLarge: RpgTextStyles.titleLarge,
        titleMedium: RpgTextStyles.titleMedium,
        titleSmall: RpgTextStyles.titleSmall,
        bodyLarge: RpgTextStyles.bodyLarge,
        bodyMedium: RpgTextStyles.bodyMedium,
        bodySmall: RpgTextStyles.bodySmall,
        labelLarge: RpgTextStyles.labelLarge,
        labelMedium: RpgTextStyles.labelMedium,
        labelSmall: RpgTextStyles.labelSmall,
      ),
    );
  }
}
