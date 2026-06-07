import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/profile.dart';

class PagePersistenceService {
  // SQLite helper instance
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static Future<Profile?> loadProfile() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _dbHelper.profileTable,
      );
      if (maps.isEmpty) return null;
      return Profile.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return null;
    }
  }

  static Future<void> saveProfile(Profile profile) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        _dbHelper.profileTable,
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      throw Exception('Failed to save profile: $e');
    }
  }

  static Future<Map<String, int>> loadHistory() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _dbHelper.historyTable,
    );
    return {
      for (var map in maps) map['date'] as String: map['pagesRead'] as int,
    };
  }

  static Future<void> saveHistory(Map<String, int> history) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    batch.delete(_dbHelper.historyTable);
    for (var entry in history.entries) {
      batch.insert(
        _dbHelper.historyTable,
        {'date': entry.key, 'pagesRead': entry.value},
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> updatePagesReadToday(int pages) async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final todayKey = _formatDate(today);

    // Check if today's entry exists
    final existing = await db.query(
      _dbHelper.historyTable,
      where: 'date = ?',
      whereArgs: [todayKey],
    );

    if (existing.isEmpty) {
      // Insert new entry
      await db.insert(
        _dbHelper.historyTable,
        {'date': todayKey, 'pagesRead': pages},
      );
    } else {
      // Update existing entry
      final currentPages = existing.first['pagesRead'] as int;
      await db.update(
        _dbHelper.historyTable,
        {'pagesRead': currentPages + pages},
        where: 'date = ?',
        whereArgs: [todayKey],
      );
    }
  }

  static String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }
}
