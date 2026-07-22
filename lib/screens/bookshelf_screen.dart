import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/bookshelf_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/empty_bookshelf.dart';
import '../widgets/theme_toggle_button.dart';
import 'reader_screen.dart';

/// The main bookshelf screen displaying all imported PDF books in a grid.
///
/// Provides:
/// - A grid of book cards with thumbnails
/// - FAB to import new PDFs
/// - Theme toggle in the app bar
/// - Long-press to delete books
class BookshelfScreen extends StatelessWidget {
  const BookshelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookshelf = context.watch<BookshelfProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 24,
              color: isDark
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFFB8941F),
            ),
            const SizedBox(width: 10),
            const Text('Book Mate'),
          ],
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 4),
        ],
      ),
      body: bookshelf.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFFB8941F),
              ),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: bookshelf.isEmpty
                  ? const EmptyBookshelf()
                  : _BookGrid(books: bookshelf.books),
            ),
      floatingActionButton: _ImportFab(isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────
// Book Grid
// ─────────────────────────────────────────────────────

class _BookGrid extends StatelessWidget {
  final List<Book> books;
  const _BookGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 24,
            crossAxisSpacing: 20,
            childAspectRatio: 0.65,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCard(
              book: book,
              onTap: () => _openReader(context, book),
              onLongPress: () => _confirmDelete(context, index, book),
            );
          },
        ),
      ),
    );
  }

  void _openReader(BuildContext context, Book book) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReaderScreen(book: book),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF141414)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Remove Book',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark
                ? const Color(0xFFE5E0D8)
                : const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Remove "${book.name}" from your bookshelf?\nThe local copy will also be deleted.',
          style: TextStyle(
            color: isDark
                ? const Color(0xFF8A8178)
                : const Color(0xFF6E6860),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFFB8941F),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<BookshelfProvider>().removeBook(index);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Import FAB with gradient
// ─────────────────────────────────────────────────────

class _ImportFab extends StatelessWidget {
  final bool isDark;
  const _ImportFab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFFD4AF37), const Color(0xFFB8941F)]
              : [const Color(0xFFB8941F), const Color(0xFF9A7F28)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () async {
          final added =
              await context.read<BookshelfProvider>().addBook();
          if (!added && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('No PDF selected or already imported'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Icon(Icons.add_rounded, size: 28,
            color: isDark ? const Color(0xFF0A0A0A) : Colors.white),
      ),
    );
  }
}
