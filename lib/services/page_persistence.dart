import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/profile.dart';

class PagePersistenceService {
  static const String _configFileName = 'profile.json';
  static const String _profileKey = 'profile';

  static const String _historyFileName = 'history.json';

  static Future<String> get _configPath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, _configFileName);
  }

  static Future<File> get _configFile async {
    final configPath = await _configPath;
    return File(configPath);
  }

  static Future<void> _createEmptyConfig() async {
    final file = await _configFile;
    final emptyConfig = {
      _profileKey: {
        'id': 'a', // Temporary default ID as i do not know what the fuck to change it to
        'pagesReadToday': 0,
      }
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(emptyConfig),
    );
  }

  static Future<Profile?> loadProfile() async {
    try {
      final file = await _configFile;

      if (!await file.exists()) {
        await _createEmptyConfig();
        return null;
      }

      final contents = await file.readAsString();
      final configData = json.decode(contents) as Map<String, dynamic>;

      final profileData = configData[_profileKey] as Map<String, dynamic>?;
      if (profileData == null) return null;

      return Profile.fromMap(profileData);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return null;
    }
  }

  static Future<void> saveProfile(Profile profile) async {
    try {
      final file = await _configFile;

      Map<String, dynamic> configData = {};
      if (await file.exists()) {
        final contents = await file.readAsString();
        configData = json.decode(contents) as Map<String, dynamic>;
      }

      configData[_profileKey] = profile.toMap();

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(configData),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      throw Exception('Failed to save profile: $e');
    }
  }

  static Future<String> get _historyPath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, _historyFileName);
  }

  static Future<File> get _historyFile async {
    final historyPath = await _historyPath;
    return File(historyPath);
  }

  static Future<Map<String, int>> loadHistory() async {
    final file = await _historyFile;
    if (!await file.exists()) {
      await _createEmptyHistory();
      return {};
    }

    final contents = await file.readAsString();
    final Map<String, dynamic> data = json.decode(contents);
    return data.map((key, value) => MapEntry(key, value as int));
  }

  static Future<void> _createEmptyHistory() async {
    final file = await _historyFile;
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert({}));
  }

  static Future<void> saveHistory(Map<String, int> history) async {
    final file = await _historyFile;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(history),
      flush: true,
    );
  }

  static Future<void> updatePagesReadToday(int pages) async {
    final history = await loadHistory();

    final today = DateTime.now();
    final todayKey = _formatDate(today);

    history[todayKey] = (history[todayKey] ?? 0) + pages;

    await saveHistory(history);
  }

  static String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }
}
