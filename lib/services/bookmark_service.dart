import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bookmark.dart';
import 'database_helper.dart';

class BookmarkService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static Future<List<Bookmark>> getBookmarks(String bookId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _dbHelper.bookmarksTable,
        where: 'bookId = ?',
        whereArgs: [bookId],
        orderBy: 'pageNumber ASC',
      );
      return List.generate(maps.length, (i) => Bookmark.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      return [];
    }
  }

  static Future<Bookmark> addBookmark(Bookmark bookmark) async {
    final db = await _dbHelper.database;
    final id = await db.insert(_dbHelper.bookmarksTable, bookmark.toMap());
    return bookmark.copyWith(id: id);
  }

  static Future<void> removeBookmark(int bookmarkId) async {
    final db = await _dbHelper.database;
    await db.delete(
      _dbHelper.bookmarksTable,
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }

  static Future<void> updateBookmarkLabel(int bookmarkId, String label) async {
    final db = await _dbHelper.database;
    await db.update(
      _dbHelper.bookmarksTable,
      {'label': label},
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }

  static Future<Bookmark?> getBookmarkAtPage(String bookId, int pageNumber) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _dbHelper.bookmarksTable,
      where: 'bookId = ? AND pageNumber = ?',
      whereArgs: [bookId, pageNumber],
    );
    if (maps.isEmpty) return null;
    return Bookmark.fromMap(maps.first);
  }

  static Future<bool> hasBookmarkAtPage(String bookId, int pageNumber) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM ${_dbHelper.bookmarksTable} WHERE bookId = ? AND pageNumber = ?',
      [bookId, pageNumber],
    ));
    return (count ?? 0) > 0;
  }

  static Future<void> removeAllBookmarks(String bookId) async {
    final db = await _dbHelper.database;
    await db.delete(
      _dbHelper.bookmarksTable,
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
  }
}
