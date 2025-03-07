import 'package:flutter/material.dart';

class LightTheme {
  static ThemeData get themeData {
    // Hauptfarbe: Ein kräftiges Blaugrau für die AppBar
    const appBarColor = Color(0xFF455A64); // Material Blue Grey 700

    // Primäre Farbe: Ein etwas helleres Blaugrau für andere Elemente
    const primaryColor = Color(0xFF546E7A); // Material Blue Grey 600

    // Sekundäre Farbe: Ein helleres Teal für Akzente
    const secondaryColor = Color(0xFF26A69A); // Teal 400

    // Hintergrundfarbe für Scaffolds (leicht getönt für besseren Kontrast)
    const backgroundColor = Color(0xFFF5F7F9); // Sehr helles Blaugrau

    // Oberflächenfarbe für Karten und andere erhöhte Elemente
    const surfaceColor = Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shadowColor: Color(
          0xFF37474F,
        ), // Dunklerer Schatten unter der AppBar (Blue Grey 800)
        iconTheme: IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        toolbarHeight: 64,
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFCFD8DC), // Blue Grey 100
        onPrimaryContainer: Color(0xFF263238), // Blue Grey 900

        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFB2DFDB), // Teal 100
        onSecondaryContainer: Color(0xFF004D40), // Teal 900

        surface: surfaceColor,
        onSurface: Color(0xFF263238), // Blue Grey 900

        error: Color(0xFFB71C1C), // Dark Red für Fehler
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.black.withOpacity(0.15),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFF263238),
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: Color(0xFF263238),
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: Color(0xFF263238),
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(color: Color(0xFF263238)),
        headlineSmall: TextStyle(color: Color(0xFF263238)),
        titleLarge: TextStyle(
          color: Color(0xFF263238),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: Color(0xFF455A64)), // Blue Grey 700
        bodyMedium: TextStyle(color: Color(0xFF455A64)), // Blue Grey 700
      ),
      iconTheme: const IconThemeData(color: Color(0xFF546E7A)), // Blue Grey 600
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF78909C), // Blue Grey 400
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFECEFF1), // Blue Grey 50
        thickness: 1,
        space: 1,
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        buttonColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: 3,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFECEFF1), // Blue Grey 50
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: TextStyle(
          color: const Color(0xFF90A4AE), // Blue Grey 300
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF37474F), // Blue Grey 800
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
