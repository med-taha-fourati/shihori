import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:Shihori/models/book.dart';

class BookPersistenceService {
  static const String _configFileName = 'config.json';
  static const String _booksKey = 'books';

  static Future<String> get _configPath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, _configFileName);
  }

  static Future<File> get _configFile async {
    final configPath = await _configPath;
    return File(configPath);
  }

  static Future<List<Book>> loadBooks() async {
    try {
      final file = await _configFile;

      if (!await file.exists()) {
        await _createEmptyConfig();
        return [];
      }

      final contents = await file.readAsString();
      final configData = json.decode(contents) as Map<String, dynamic>;

      final booksData = configData[_booksKey] as List<dynamic>?;
      if (booksData == null) return [];

      return booksData
          .map((bookMap) => Book.fromMap(bookMap as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading books: $e');
      return [];
    }
  }

  static Future<void> saveBooks(List<Book> books) async {
    try {
      final file = await _configFile;

      Map<String, dynamic> configData = {};
      if (await file.exists()) {
        final contents = await file.readAsString();
        configData = json.decode(contents) as Map<String, dynamic>;
      }

      configData[_booksKey] = books.map((book) => book.toMap()).toList();

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(configData),
      );
    } catch (e) {
      print('Error saving books: $e');
      throw Exception('Failed to save books: $e');
    }
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
    final books = await loadBooks();

    final existingBook = books.indexWhere((book) => book.id == id);

    books[existingBook] = books[existingBook].copyWith(
      isFavorite: !books[existingBook].isFavorite
    );

    await saveBooks(books);
  }

  static Future<void> addBook(Book book) async {
    final books = await loadBooks();

    final existingIndex = books.indexWhere((b) => b.id == book.id);
    if (existingIndex != -1) {
      throw Exception('Book with ID ${book.id} already exists');
    }

    books.add(book);
    await saveBooks(books);
  }

  static Future<void> updateBook(Book updatedBook) async {
    final books = await loadBooks();
    final index = books.indexWhere((book) => book.id == updatedBook.id);

    if (index == -1) {
      throw Exception('Book with ID ${updatedBook.id} not found');
    }

    books[index] = updatedBook;
    await saveBooks(books);
  }

  static Future<void> updateLastReadPage(String bookId, int page) async {
    final books = await loadBooks();
    final index = books.indexWhere((book) => book.id == bookId);

    if (index == -1) {
      throw Exception('Book with ID $bookId not found');
    }

    books[index] = books[index].copyWith(
      lastReadPage: page,
      lastOpened: DateTime.now(),
    );

    await saveBooks(books);
  }

  static Future<void> removeBook(String bookId) async {
    final books = await loadBooks();
    books.removeWhere((book) => book.id == bookId);
    await saveBooks(books);
  }

  static Future<Book?> getBookById(String bookId) async {
    final books = await loadBooks();
    try {
      return books.firstWhere((book) => book.id == bookId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearAllBooks() async {
    await saveBooks([]);
  }

  static Future<bool> configExists() async {
    final file = await _configFile;
    return await file.exists();
  }

  static Future<String> getConfigPath() async {
    return await _configPath;
  }

  static Future<void> _createEmptyConfig() async {
    final file = await _configFile;
    final emptyConfig = {_booksKey: []};
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(emptyConfig),
    );
  }

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