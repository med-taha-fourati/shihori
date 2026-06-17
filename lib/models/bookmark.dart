class Bookmark {
  final int? id;
  final String bookId;
  final int pageNumber;
  final String? label;
  final DateTime createdAt;

  Bookmark({
    this.id,
    required this.bookId,
    required this.pageNumber,
    this.label,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bookId': bookId,
      'pageNumber': pageNumber,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      bookId: map['bookId'] as String,
      pageNumber: map['pageNumber'] as int,
      label: map['label'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Bookmark copyWith({
    int? id,
    String? bookId,
    int? pageNumber,
    String? label,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageNumber: pageNumber ?? this.pageNumber,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
