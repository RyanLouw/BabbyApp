import 'package:flutter/material.dart';
class AppTheme {
  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);
  static ThemeData _theme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(seedColor: const Color(0xff6f8173), brightness: brightness);
    return ThemeData(useMaterial3: true, colorScheme: colors,
      scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xff151815) : const Color(0xfffaf8f3),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 52))));
  }
}
