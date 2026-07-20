import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/book.dart';

/// Manages the in-memory collection of imported PDF books.
class BookshelfProvider extends ChangeNotifier {
  final List<Book> _books = [];

  List<Book> get books => List.unmodifiable(_books);

  bool get isEmpty => _books.isEmpty;

  /// Opens the system file picker, allowing the user to select a PDF file.
  /// Returns `true` if a book was successfully added.
  Future<bool> addBook() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return false;

    final file = result.files.first;
    final filePath = file.path;

    if (filePath == null) return false;

    // Avoid duplicates
    if (_books.any((b) => b.path == filePath)) return false;

    final fileName = p.basenameWithoutExtension(filePath);

    _books.add(Book(
      name: fileName,
      path: filePath,
      addedAt: DateTime.now(),
    ));

    notifyListeners();
    return true;
  }

  /// Removes a book at the given index.
  void removeBook(int index) {
    if (index >= 0 && index < _books.length) {
      _books.removeAt(index);
      notifyListeners();
    }
  }

  /// Removes a book by its model reference.
  void removeBookByModel(Book book) {
    _books.remove(book);
    notifyListeners();
  }
}
