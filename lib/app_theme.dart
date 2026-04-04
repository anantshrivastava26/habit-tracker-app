import 'package:flutter/material.dart';
import 'widgets/neu_box.dart';

class AppTheme {
  static ThemeData get light => _buildTheme(isDark: false);
  static ThemeData get dark => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final bg = NeuColors.background(isDark);
    final textPrimary = NeuColors.textPrimary(isDark);
    final textSecondary = NeuColors.textSecondary(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NeuColors.primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: bg,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: bg,

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textPrimary),
        displayMedium: TextStyle(color: textPrimary),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        foregroundColor: textPrimary,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _outlineBorder(),
        enabledBorder: _outlineBorder(),
        focusedBorder: _outlineBorder(),
        errorBorder: _outlineBorder(color: Colors.red, width: 1),
        hintStyle: TextStyle(color: textSecondary),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NeuColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static OutlineInputBorder _outlineBorder(
      {Color color = Colors.transparent, double width = 0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: color == Colors.transparent
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }
}
