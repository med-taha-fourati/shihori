import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';
import 'package:Shihori/models/book.dart';

class BookPersistenceService {
  // SQLite helper instance
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static Future<List<Book>> loadBooks() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_dbHelper.booksTable);
      return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
    } catch (e) {
      print('Error loading books: $e');
      return [];
    }
  }

  static Future<void> saveBooks(List<Book> books) async {
    final db = await _dbHelper.database;
    // Replace existing data with new list
    final batch = db.batch();
    batch.delete(_dbHelper.booksTable);
    for (var book in books) {
      batch.insert(_dbHelper.booksTable, book.toMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<int> getTotalPages() async {
    final books = await loadBooks();

    int count = 0;
    books.forEach((book) => count += book.pageCount);

    return count;
  }

  static Future<int> getPagesRead() async {
    final books = await loadBooks();

    int count = 0;

    books.forEach((book) => count += book.lastReadPage);
    return count;
  }

  static Future<int> getCompletedBooks() async {
    final books = await loadBooks();

    int count = 0;
    count = books.where((book) => book.lastReadPage >= book.pageCount).length;
    return count;
  }

  static Future<int> getInProgressBooks() async {
    final books = await loadBooks();

    int count = 0;
    count = books.where((book) => book.lastReadPage < book.pageCount).length;
    return count;
  }

  static Future<void> favoriteABook(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      _dbHelper.booksTable,
      columns: ['isFavorite'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return;
    final current = result.first['isFavorite'] as int? ?? 0;
    await db.update(
      _dbHelper.booksTable,
      {'isFavorite': current == 0 ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> addBook(Book book) async {
    final db = await _dbHelper.database;
    // Ensure no duplicate
    final existing = await db.query(
      _dbHelper.booksTable,
      where: 'id = ?',
      whereArgs: [book.id],
    );
    if (existing.isNotEmpty) {
      throw Exception('Book with ID ${book.id} already exists');
    }
    await db.insert(_dbHelper.booksTable, book.toMap());
  }

  static Future<void> updateBook(Book updatedBook) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      _dbHelper.booksTable,
      updatedBook.toMap(),
      where: 'id = ?',
      whereArgs: [updatedBook.id],
    );
    if (count == 0) {
      throw Exception('Book with ID ${updatedBook.id} not found');
    }
  }

  static Future<void> updateLastReadPage(String bookId, int page) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      _dbHelper.booksTable,
      {
        'lastReadPage': page,
        'lastOpened': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
    if (count == 0) {
      throw Exception('Book with ID $bookId not found');
    }
  }

  static Future<void> removeBook(String bookId) async {
    final db = await _dbHelper.database;
    await db.delete(
      _dbHelper.booksTable,
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  static Future<Book?> getBookById(String bookId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _dbHelper.booksTable,
      where: 'id = ?',
      whereArgs: [bookId],
    );
    if (maps.isEmpty) return null;
    return Book.fromMap(maps.first);
  }

  static Future<void> clearAllBooks() async {
    final db = await _dbHelper.database;
    await db.delete(_dbHelper.booksTable);
  }

  // The following JSON‑based helpers are no longer needed with SQLite.
  // They are kept as stubs for compatibility if any legacy code calls them.
  static Future<bool> configExists() async => true;
  static Future<String> getConfigPath() async => '';

  static Future<void> backupBooks({String backupFileName = 'books_backup.json'}) async {
    try {
      final books = await loadBooks();
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File(path.join(directory.path, backupFileName));

      final backupData = {
        'books': books.map((book) => book.toMap()).toList(),
        'backup_date': DateTime.now().toIso8601String(),
      };

      await backupFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );
    } catch (e) {
      throw Exception('Failed to backup books: $e');
    }
  }

  static Future<void> restoreFromBackup({String backupFileName = 'books_backup.json'}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File(path.join(directory.path, backupFileName));

      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }

      final contents = await backupFile.readAsString();
      final backupData = json.decode(contents) as Map<String, dynamic>;
      final booksData = backupData['books'] as List<dynamic>;

      final books = booksData
          .map((bookMap) => Book.fromMap(bookMap as Map<String, dynamic>))
          .toList();

      await saveBooks(books);
    } catch (e) {
      throw Exception('Failed to restore from backup: $e');
    }
  }
}