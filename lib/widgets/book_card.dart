import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../models/book.dart';

/// A card widget displaying a book's thumbnail and title on the bookshelf.
///
/// Renders the first page of the PDF as a cover thumbnail.
/// Supports tap to open and long-press to delete.
class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard>
    with SingleTickerProviderStateMixin {
  Uint8List? _thumbnail;
  bool _loading = true;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final document = await PdfDocument.openData(File(widget.book.path).readAsBytesSync());
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      await document.close();

      if (mounted) {
        setState(() {
          _thumbnail = pageImage?.bytes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      onLongPress: () {
        _scaleController.reverse();
        widget.onLongPress();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book cover
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black54
                          : const Color(0xFF6B4EFF).withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    if (!isDark)
                      BoxShadow(
                        color:
                            const Color(0xFF6B4EFF).withValues(alpha: 0.06),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _loading
                      ? Container(
                          color: isDark
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFFF0EDFF),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? const Color(0xFF9B85FF)
                                    : const Color(0xFF6B4EFF),
                              ),
                            ),
                          ),
                        )
                      : _thumbnail != null
                          ? Image.memory(
                              _thumbnail!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: isDark
                                  ? const Color(0xFF1A1A2E)
                                  : const Color(0xFFF0EDFF),
                              child: Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 40,
                                color: isDark
                                    ? const Color(0xFF9B85FF)
                                    : const Color(0xFF6B4EFF),
                              ),
                            ),
                ),
              ),
            ),

            // Book title
            const SizedBox(height: 10),
            Text(
              widget.book.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFCCC4E0)
                    : const Color(0xFF2D2D44),
                letterSpacing: -0.2,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
