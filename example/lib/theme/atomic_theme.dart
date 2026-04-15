import 'package:flutter/material.dart';

// Brand Colors
const atomicPurple = Color(0xFF7C5CFC);
const atomicPurpleLight = Color(0xFFB4A0FF);

// Dark Theme Palette
const atomicBackground = Color(0xFF0F1117);
const atomicSurface = Color(0xFF1A1D27);
const atomicSurfaceVariant = Color(0xFF252833);
const atomicOnBackground = Color(0xFFE8EAF0);
const atomicOnSurfaceVariant = Color(0xFF8B8FA3);
const atomicOutline = Color(0xFF2E3140);

// Event Colors
const eventBlue = Color(0xFF2196F3);
const eventGreen = Color(0xFF4CAF50);
const eventIndigo = Color(0xFF3F51B5);
const eventCyan = Color(0xFF00BCD4);
const eventMint = Color(0xFF26A69A);
const eventOrange = Color(0xFFFF9800);
const eventRed = Color(0xFFF44336);

final atomicColorScheme = ColorScheme.dark(
  primary: atomicPurple,
  onPrimary: Colors.white,
  primaryContainer: atomicPurple,
  onPrimaryContainer: Colors.white,
  secondary: atomicPurpleLight,
  onSecondary: atomicBackground,
  surface: atomicSurface,
  onSurface: atomicOnBackground,
  surfaceContainerHighest: atomicSurfaceVariant,
  surfaceContainerHigh: atomicSurface,
  surfaceContainerLow: atomicBackground,
  surfaceContainerLowest: atomicBackground,
  outline: atomicOutline,
  outlineVariant: atomicOutline,
);

ThemeData buildAtomicTheme() {
  return ThemeData(
    colorScheme: atomicColorScheme,
    scaffoldBackgroundColor: atomicBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: atomicBackground,
      foregroundColor: atomicOnBackground,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: atomicSurface,
      indicatorColor: atomicPurple.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: atomicPurple,
          );
        }
        return const TextStyle(
          fontSize: 12,
          color: atomicOnSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: atomicPurple);
        }
        return const IconThemeData(color: atomicOnSurfaceVariant);
      }),
    ),
    dividerTheme: const DividerThemeData(color: atomicOutline),
    cardTheme: CardThemeData(
      color: atomicSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: atomicOutline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: atomicSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: atomicOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: atomicOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: atomicPurple),
      ),
      hintStyle: const TextStyle(color: atomicOnSurfaceVariant),
    ),
    useMaterial3: true,
  );
}
