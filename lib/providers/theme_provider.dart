import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';
  static const String _useDynamicColorKey = 'use_dynamic_color';

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.purple;
  bool _useDynamicColor = true;
  ColorScheme? _dynamicLightColorScheme;
  ColorScheme? _dynamicDarkColorScheme;

  ThemeProvider() {
    _loadPreferences();
    _loadDynamicColors();
  }

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get useDynamicColor => _useDynamicColor;
  ColorScheme? get dynamicLightColorScheme => _dynamicLightColorScheme;
  ColorScheme? get dynamicDarkColorScheme => _dynamicDarkColorScheme;

  bool get isDynamicColorAvailable =>
      _dynamicLightColorScheme != null && _dynamicDarkColorScheme != null;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final colorValue = prefs.getInt(_seedColorKey) ?? Colors.purple.value;
    final useDynamic = prefs.getBool(_useDynamicColorKey) ?? true;

    _themeMode = ThemeMode.values[themeIndex];
    _seedColor = Color(colorValue);
    _useDynamicColor = useDynamic;

    notifyListeners();
  }

  Future<void> _loadDynamicColors() async {
    try {
      final corePalette = await DynamicColorPlugin.getCorePalette();
      if (corePalette != null) {
        _dynamicLightColorScheme = corePalette.toColorScheme();
        _dynamicDarkColorScheme = corePalette.toColorScheme(brightness: Brightness.dark);
      }
    } catch (e) {
      print('Dynamic colors not available: $e');
      _dynamicLightColorScheme = null;
      _dynamicDarkColorScheme = null;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.value);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool useDynamic) async {
    _useDynamicColor = useDynamic;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorKey, useDynamic);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeMode.index);
    notifyListeners();
  }

  Future<void> refreshDynamicColors() async {
    await _loadDynamicColors();
  }

  ColorScheme getLightColorScheme() {
    if (_useDynamicColor && _dynamicLightColorScheme != null) {
      return _dynamicLightColorScheme!;
    }
    return ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
  }

  ColorScheme getDarkColorScheme() {
    if (_useDynamicColor && _dynamicDarkColorScheme != null) {
      return _dynamicDarkColorScheme!;
    }
    return ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
  }

  ThemeData getLightTheme() {
    return ThemeData(
      colorScheme: getLightColorScheme(),
      useMaterial3: true,
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      colorScheme: getDarkColorScheme(),
      useMaterial3: true,
    );
  }
}