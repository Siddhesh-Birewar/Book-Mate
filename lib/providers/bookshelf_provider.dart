import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import '../models/book.dart';
import '../services/pdf_service.dart';

/// Manages the persistent collection of imported PDF books.
///
/// On initialization, loads saved books from SharedPreferences.
/// Every mutation (add/remove) auto-saves to disk.
class BookshelfProvider extends ChangeNotifier {
  final List<Book> _books = [];
  bool _isLoading = true;

  BookshelfProvider() {
    _init();
  }

  List<Book> get books => List.unmodifiable(_books);
  bool get isEmpty => _books.isEmpty;
  bool get isLoading => _isLoading;

  /// Load saved books from persistent storage on startup.
  Future<void> _init() async {
    final savedBooks = await PdfService.loadBooks();
    _books.addAll(savedBooks);
    _isLoading = false;
    notifyListeners();
  }

  /// Opens the system file picker, copies the PDF to app storage,
  /// reads page count, and persists the book metadata.
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

    // Avoid duplicates by original path
    if (_books.any((b) => b.path == filePath)) return false;

    // Copy PDF to app's local storage
    final localPath = await PdfService.copyToAppDir(filePath);
    final fileName = p.basenameWithoutExtension(filePath);

    // Read total page count
    int totalPages = 0;
    try {
      final doc = await PdfDocument.openData(
        File(localPath).readAsBytesSync(),
      );
      totalPages = doc.pagesCount;
      await doc.close();
    } catch (_) {
      // If we can't read pages, still add the book
    }

    final book = Book(
      name: fileName,
      path: filePath,
      localPath: localPath,
      addedAt: DateTime.now(),
      totalPages: totalPages,
      lastReadPage: 0,
    );

    _books.add(book);
    await PdfService.saveBooks(_books);
    notifyListeners();
    return true;
  }

  /// Updates reading progress for a book and persists it.
  Future<void> updateReadingProgress(String localPath, int page) async {
    final index = _books.indexWhere((b) => b.localPath == localPath);
    if (index != -1) {
      _books[index].lastReadPage = page;
      await PdfService.saveBooks(_books);
      notifyListeners();
    }
  }

  /// Update total page count if it wasn't set during import.
  Future<void> updateTotalPages(String localPath, int totalPages) async {
    final index = _books.indexWhere((b) => b.localPath == localPath);
    if (index != -1 && _books[index].totalPages != totalPages) {
      _books[index].totalPages = totalPages;
      await PdfService.saveBooks(_books);
      notifyListeners();
    }
  }

  /// Removes a book at the given index, deletes its local copy.
  Future<void> removeBook(int index) async {
    if (index >= 0 && index < _books.length) {
      final book = _books.removeAt(index);
      await PdfService.deleteLocalCopy(book.localPath);
      await PdfService.saveBooks(_books);
      notifyListeners();
    }
  }

  /// Removes a book by its model reference.
  Future<void> removeBookByModel(Book book) async {
    _books.remove(book);
    await PdfService.deleteLocalCopy(book.localPath);
    await PdfService.saveBooks(_books);
    notifyListeners();
  }
}
