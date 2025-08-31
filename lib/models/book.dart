import 'dart:io';
import 'package:path/path.dart' as path;

class Book {
  final String id;
  final String title;
  final String filePath;
  final String? coverImagePath;
  final int pageCount;
  final int lastReadPage;
  final DateTime lastOpened;
  final DateTime dateAdded;

  Book({
    required this.id,
    required this.title,
    required this.filePath,
    this.coverImagePath,
    this.pageCount = 0,
    this.lastReadPage = 0,
    DateTime? lastOpened,
    DateTime? dateAdded,
  })  : lastOpened = lastOpened ?? DateTime.now(),
        dateAdded = dateAdded ?? DateTime.now();

  String get fileName => path.basename(filePath);
  String get fileExtension => path.extension(filePath).toLowerCase();
  String get fileSize {
    final file = File(filePath);
    final sizeInBytes = file.lengthSync();
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  double get progress => pageCount > 0 ? lastReadPage / pageCount : 0;

  Book copyWith({
    String? id,
    String? title,
    String? filePath,
    String? coverImagePath,
    int? pageCount,
    int? lastReadPage,
    DateTime? lastOpened,
    DateTime? dateAdded,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      pageCount: pageCount ?? this.pageCount,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      lastOpened: lastOpened ?? this.lastOpened,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'coverImagePath': coverImagePath,
      'pageCount': pageCount,
      'lastReadPage': lastReadPage,
      'lastOpened': lastOpened.toIso8601String(),
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      filePath: map['filePath'],
      coverImagePath: map['coverImagePath'],
      pageCount: map['pageCount'] ?? 0,
      lastReadPage: map['lastReadPage'] ?? 0,
      lastOpened: DateTime.parse(map['lastOpened']),
      dateAdded: DateTime.parse(map['dateAdded']),
    );
  }
}
