import 'dart:io';
import 'package:path/path.dart' as path;

class Profile {
  final String id;
  final int pagesReadToday;

  Profile({
    required this.id,
    required this.pagesReadToday
  });

  Profile copyWith({
    String? id,
    int? pagesReadToday,
  }) {
    return Profile(id: id ?? this.id,
        pagesReadToday: pagesReadToday ?? this.pagesReadToday);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pagesReadToday': pagesReadToday
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
        id: map['id'],
        pagesReadToday: map['pagesReadToday']
    );
  }
}
