import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// A singleton helper that manages the SQLite database connection and schema.
class DatabaseHelper {
  static const _dbFileName = 'shihori.db';
  static const _booksTable = 'books';
  static const _profileTable = 'profile';
  static const _historyTable = 'history';
  static const _bookmarksTable = 'bookmarks';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbFileName);
    return await openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_booksTable (
        id TEXT PRIMARY KEY,
        title TEXT,
        filePath TEXT,
        coverImagePath TEXT,
        author TEXT,
        pageCount INTEGER,
        lastReadPage INTEGER,
        lastOpened TEXT,
        isFavorite INTEGER,
        dateAdded TEXT,
        bookmarked INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $_profileTable (
        id TEXT PRIMARY KEY,
        pagesReadToday INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $_historyTable (
        date TEXT PRIMARY KEY,
        pagesRead INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $_bookmarksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId TEXT,
        pageNumber INTEGER,
        label TEXT,
        createdAt TEXT,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_booksTable RENAME COLUMN addedDate TO dateAdded');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE $_bookmarksTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bookId TEXT,
          pageNumber INTEGER,
          label TEXT,
          createdAt TEXT,
          FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  /// Public accessor so other services can reference table/column names.
  String get booksTable => _booksTable;
  String get profileTable => _profileTable;
  String get historyTable => _historyTable;
  String get bookmarksTable => _bookmarksTable;
}