import 'package:flutter/material.dart';
import 'package:way_to_class/theme/dark_theme.dart';
import 'package:way_to_class/theme/light_theme.dart';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLightMode() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  void setDarkMode() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  static ThemeData getLightTheme() {
    return LightTheme.themeData;
  }

  static ThemeData getDarkTheme() {
    return DarkTheme.themeData;
  }
}
