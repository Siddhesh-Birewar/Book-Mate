/// Data model representing an imported PDF book.
class Book {
  final String name;
  final String path;
  final DateTime addedAt;

  const Book({
    required this.name,
    required this.path,
    required this.addedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'Book(name: $name, path: $path)';
}
