import 'dart:convert';

/// Data model representing an imported PDF book with persistence support.
class Book {
  final String name;
  final String path;        // Original path from file picker
  final String localPath;   // Copied path in app documents directory
  final DateTime addedAt;
  int totalPages;
  int lastReadPage;

  Book({
    required this.name,
    required this.path,
    required this.localPath,
    required this.addedAt,
    this.totalPages = 0,
    this.lastReadPage = 0,
  });

  /// Serialize to JSON map for SharedPreferences storage.
  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'localPath': localPath,
        'addedAt': addedAt.toIso8601String(),
        'totalPages': totalPages,
        'lastReadPage': lastReadPage,
      };

  /// Deserialize from JSON map.
  factory Book.fromJson(Map<String, dynamic> json) => Book(
        name: json['name'] as String,
        path: json['path'] as String,
        localPath: json['localPath'] as String? ?? json['path'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
        totalPages: json['totalPages'] as int? ?? 0,
        lastReadPage: json['lastReadPage'] as int? ?? 0,
      );

  /// Encode entire list to JSON string for SharedPreferences.
  static String encodeList(List<Book> books) =>
      jsonEncode(books.map((b) => b.toJson()).toList());

  /// Decode list from JSON string.
  static List<Book> decodeList(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          localPath == other.localPath;

  @override
  int get hashCode => localPath.hashCode;

  @override
  String toString() => 'Book(name: $name, localPath: $localPath, '
      'page: $lastReadPage/$totalPages)';
}
