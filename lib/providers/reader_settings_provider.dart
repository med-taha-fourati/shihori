import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ScrollDirection { vertical, horizontal }
enum ScrollMode { continuous, pageByPage }

class ReaderSettingsProvider with ChangeNotifier {
  static const String _grayscaleKey = 'reader_grayscale';
  static const String _invertColorsKey = 'reader_invert_colors';
  static const String _scrollDirectionKey = 'reader_scroll_direction';
  static const String _scrollModeKey = 'reader_scroll_mode';

  bool _grayscale = false;
  bool _invertColors = false;
  ScrollDirection _scrollDirection = ScrollDirection.vertical;
  ScrollMode _scrollMode = ScrollMode.continuous;

  ReaderSettingsProvider() {
    _loadSettings();
  }

  bool get grayscale => _grayscale;
  bool get invertColors => _invertColors;
  ScrollDirection get scrollDirection => _scrollDirection;
  ScrollMode get scrollMode => _scrollMode;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _grayscale = prefs.getBool(_grayscaleKey) ?? false;
    _invertColors = prefs.getBool(_invertColorsKey) ?? false;
    _scrollDirection = ScrollDirection.values[prefs.getInt(_scrollDirectionKey) ?? 0];
    _scrollMode = ScrollMode.values[prefs.getInt(_scrollModeKey) ?? 0];
    notifyListeners();
  }

  Future<void> setGrayscale(bool value) async {
    _grayscale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_grayscaleKey, value);
    notifyListeners();
  }

  Future<void> setInvertColors(bool value) async {
    _invertColors = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_invertColorsKey, value);
    notifyListeners();
  }

  Future<void> setScrollDirection(ScrollDirection direction) async {
    _scrollDirection = direction;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scrollDirectionKey, direction.index);
    notifyListeners();
  }

  Future<void> setScrollMode(ScrollMode mode) async {
    _scrollMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scrollModeKey, mode.index);
    notifyListeners();
  }
}
