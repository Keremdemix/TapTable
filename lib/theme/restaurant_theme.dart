import 'package:flutter/material.dart';

Color hexToColor(String hex) {
  var value = hex.replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

ThemeData buildRestaurantTheme({
  required String primaryColorHex,
  required String accentColorHex,
}) {
  final primary = hexToColor(primaryColorHex);
  final accent = hexToColor(accentColorHex);

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: primary,
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      side: BorderSide(color: primary.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Colors.black54, height: 1.3),
    ),
  );
}