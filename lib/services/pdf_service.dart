import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

/// Core PDF storage engine.
///
/// Responsibilities:
/// - Copy picked PDFs into the app's local documents directory
/// - Persist/restore book metadata + reading progress via SharedPreferences
/// - Delete local copies when books are removed
class PdfService {
  static const String _booksKey = 'bookmate_books';
  static const String _booksDirName = 'books';

  /// Get or create the app-local books directory.
  static Future<Directory> _getBooksDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(appDir.path, _booksDirName));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  /// Copy a picked PDF file into the app's local storage.
  /// Returns the new local path.
  static Future<String> copyToAppDir(String sourcePath) async {
    final booksDir = await _getBooksDir();
    final fileName = p.basename(sourcePath);

    // Avoid overwriting: append timestamp if file exists
    String destPath = p.join(booksDir.path, fileName);
    if (await File(destPath).exists()) {
      final baseName = p.basenameWithoutExtension(fileName);
      final ext = p.extension(fileName);
      destPath = p.join(
        booksDir.path,
        '${baseName}_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
    }

    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Load all saved books from SharedPreferences.
  static Future<List<Book>> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_booksKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final books = Book.decodeList(jsonStr);
      // Verify local files still exist
      final validBooks = <Book>[];
      for (final book in books) {
        if (await File(book.localPath).exists()) {
          validBooks.add(book);
        }
      }
      return validBooks;
    } catch (_) {
      return [];
    }
  }

  /// Save the entire book list to SharedPreferences.
  static Future<void> saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_booksKey, Book.encodeList(books));
  }

  /// Update reading progress for a specific book and persist.
  static Future<void> saveReadingProgress(
    List<Book> books,
    String localPath,
    int page,
  ) async {
    final index = books.indexWhere((b) => b.localPath == localPath);
    if (index != -1) {
      books[index].lastReadPage = page;
      await saveBooks(books);
    }
  }

  /// Delete the local PDF file copy.
  static Future<void> deleteLocalCopy(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
