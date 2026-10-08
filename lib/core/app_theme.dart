import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color darkBackground = Color(0xFF0A0E21);
  static const Color darkSurface = Color(0xFF1D1E33);
  static const Color goldPrimary = Color(0xFFC5A021);
  static const Color deepBlueAccent = Color(0xFF1A237E);
  static const Color lightBackground = Color(0xFFF4F5F7);
  static const Color lightSurface = Colors.white;

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: goldPrimary,
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: goldPrimary,
      secondary: goldPrimary,
      surface: darkSurface,
      background: darkBackground,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
    textTheme: ThemeData.dark().textTheme.copyWith(
      headlineMedium: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      bodyLarge: const TextStyle(color: Colors.white70),
    ).apply(bodyColor: Colors.white, displayColor: Colors.white),
  );

  static ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: deepBlueAccent,
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    colorScheme: const ColorScheme.light(
      primary: deepBlueAccent,
      secondary: goldPrimary,
      surface: lightSurface,
      background: lightBackground,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
