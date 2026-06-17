import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import 'book_persistence.dart';
import 'page_persistence.dart';

class MigrationPreview {
  final int totalBooksInJson;
  final int newBooks;
  final int totalHistoryInJson;
  final int newHistoryEntries;
  final List<String> errors;

  MigrationPreview({
    required this.totalBooksInJson,
    required this.newBooks,
    required this.totalHistoryInJson,
    required this.newHistoryEntries,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasMigratableData => newBooks > 0 || newHistoryEntries > 0;
}

class MigrationResult {
  final int booksMigrated;
  final int historyEntriesMigrated;
  final List<String> errors;

  MigrationResult({
    required this.booksMigrated,
    required this.historyEntriesMigrated,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasMigratedAnything => booksMigrated > 0 || historyEntriesMigrated > 0;
}

class JsonMigratorService {
  static const String _booksBackupFile = 'books_backup.json';
  static const String _historyBackupFile = 'history_backup.json';

  static Future<MigrationResult> migrateJsonToSqlite() async {
    final errors = <String>[];
    int booksMigrated = 0;
    int historyEntriesMigrated = 0;

    final directory = await getApplicationDocumentsDirectory();

    final booksFile = File(path.join(directory.path, _booksBackupFile));
    if (await booksFile.exists()) {
      try {
        final contents = await booksFile.readAsString();
        final data = json.decode(contents) as Map<String, dynamic>;
        final booksData = data['books'] as List<dynamic>;

        final books = booksData
            .map((bookMap) => Book.fromMap(bookMap as Map<String, dynamic>))
            .toList();

        final existingBooks = await BookPersistenceService.loadBooks();
        final existingIds = existingBooks.map((b) => b.id).toSet();
        final newBooks = books.where((b) => !existingIds.contains(b.id)).toList();

        if (newBooks.isNotEmpty) {
          final allBooks = [...existingBooks, ...newBooks];
          await BookPersistenceService.saveBooks(allBooks);
          booksMigrated = newBooks.length;
        }
      } catch (e) {
        errors.add('Failed to migrate books: $e');
        debugPrint('Error migrating books from JSON: $e');
      }
    }

    final historyFile = File(path.join(directory.path, _historyBackupFile));
    if (await historyFile.exists()) {
      try {
        final contents = await historyFile.readAsString();
        final data = json.decode(contents) as Map<String, dynamic>;
        final historyData = data['history'] as Map<String, dynamic>;

        final existingHistory = await PagePersistenceService.loadHistory();
        final mergedHistory = Map<String, int>.from(existingHistory);

        int newEntries = 0;
        for (final entry in historyData.entries) {
          if (!mergedHistory.containsKey(entry.key)) {
            mergedHistory[entry.key] = entry.value as int;
            newEntries++;
          }
        }

        if (newEntries > 0) {
          await PagePersistenceService.saveHistory(mergedHistory);
          historyEntriesMigrated = newEntries;
        }
      } catch (e) {
        errors.add('Failed to migrate history: $e');
        debugPrint('Error migrating history from JSON: $e');
      }
    }

    return MigrationResult(
      booksMigrated: booksMigrated,
      historyEntriesMigrated: historyEntriesMigrated,
      errors: errors,
    );
  }

  static Future<MigrationPreview> previewJsonData() async {
    final errors = <String>[];
    int totalBooksInJson = 0;
    int newBooks = 0;
    int totalHistoryInJson = 0;
    int newHistoryEntries = 0;

    final directory = await getApplicationDocumentsDirectory();

    final booksFile = File(path.join(directory.path, _booksBackupFile));
    if (await booksFile.exists()) {
      try {
        final contents = await booksFile.readAsString();
        final data = json.decode(contents) as Map<String, dynamic>;
        final booksData = data['books'] as List<dynamic>;

        final books = booksData
            .map((bookMap) => Book.fromMap(bookMap as Map<String, dynamic>))
            .toList();

        totalBooksInJson = books.length;

        final existingBooks = await BookPersistenceService.loadBooks();
        final existingIds = existingBooks.map((b) => b.id).toSet();
        newBooks = books.where((b) => !existingIds.contains(b.id)).length;
      } catch (e) {
        errors.add('Failed to read books backup: $e');
        debugPrint('Error previewing books from JSON: $e');
      }
    }

    final historyFile = File(path.join(directory.path, _historyBackupFile));
    if (await historyFile.exists()) {
      try {
        final contents = await historyFile.readAsString();
        final data = json.decode(contents) as Map<String, dynamic>;
        final historyData = data['history'] as Map<String, dynamic>;

        totalHistoryInJson = historyData.length;

        final existingHistory = await PagePersistenceService.loadHistory();

        for (final entry in historyData.entries) {
          if (!existingHistory.containsKey(entry.key)) {
            newHistoryEntries++;
          }
        }
      } catch (e) {
        errors.add('Failed to read history backup: $e');
        debugPrint('Error previewing history from JSON: $e');
      }
    }

    return MigrationPreview(
      totalBooksInJson: totalBooksInJson,
      newBooks: newBooks,
      totalHistoryInJson: totalHistoryInJson,
      newHistoryEntries: newHistoryEntries,
      errors: errors,
    );
  }

  static Future<bool> hasJsonFilesToMigrate() async {
    final directory = await getApplicationDocumentsDirectory();
    final booksFile = File(path.join(directory.path, _booksBackupFile));
    final historyFile = File(path.join(directory.path, _historyBackupFile));
    return await booksFile.exists() || await historyFile.exists();
  }
}
