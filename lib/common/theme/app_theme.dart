import 'package:flutter/material.dart' as mat;

class AppTheme {
  static final _lightColorScheme = mat.ColorScheme.fromSeed(
    seedColor: mat.Colors.deepPurple,
    brightness: mat.Brightness.light,
  );

  static final _darkColorScheme = mat.ColorScheme.fromSeed(
    seedColor: mat.Colors.deepPurple,
    brightness: mat.Brightness.dark,
  );

  static final lightTheme = mat.ThemeData(
    colorScheme: _lightColorScheme,
    useMaterial3: true,
    appBarTheme: mat.AppBarTheme(
      backgroundColor: _lightColorScheme.primaryContainer,
      foregroundColor: _lightColorScheme.onPrimaryContainer,
      elevation: 0,
    ),
    cardTheme: mat.CardThemeData(
      clipBehavior: mat.Clip.antiAlias,
      elevation: 2,
      shape: mat.RoundedRectangleBorder(
        borderRadius: mat.BorderRadius.circular(16),
      ),
    ),
    floatingActionButtonTheme: mat.FloatingActionButtonThemeData(
      backgroundColor: _lightColorScheme.primary,
      foregroundColor: _lightColorScheme.onPrimary,
      shape: const mat.RoundedRectangleBorder(
        borderRadius: mat.BorderRadius.all(mat.Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: mat.InputDecorationTheme(
      border: mat.OutlineInputBorder(
        borderRadius: mat.BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: _lightColorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
    ),
  );

  static final darkTheme = mat.ThemeData(
    colorScheme: _darkColorScheme,
    useMaterial3: true,
    appBarTheme: mat.AppBarTheme(
      backgroundColor: _darkColorScheme.primaryContainer,
      foregroundColor: _darkColorScheme.onPrimaryContainer,
      elevation: 0,
    ),
    cardTheme: mat.CardThemeData(
      clipBehavior: mat.Clip.antiAlias,
      elevation: 2,
      shape: mat.RoundedRectangleBorder(
        borderRadius: mat.BorderRadius.circular(16),
      ),
    ),
    floatingActionButtonTheme: mat.FloatingActionButtonThemeData(
      backgroundColor: _darkColorScheme.primary,
      foregroundColor: _darkColorScheme.onPrimary,
      shape: const mat.RoundedRectangleBorder(
        borderRadius: mat.BorderRadius.all(mat.Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: mat.InputDecorationTheme(
      border: mat.OutlineInputBorder(
        borderRadius: mat.BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: _darkColorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
    ),
  );
}
