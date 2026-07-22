import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../models/book.dart';

/// A card widget displaying a book's thumbnail and title on the bookshelf.
///
/// Renders the first page of the PDF as a cover thumbnail.
/// Shows reading progress indicator.
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
      final document = await PdfDocument.openData(
        File(widget.book.localPath).readAsBytesSync(),
      );
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
    final progress = widget.book.totalPages > 0
        ? widget.book.lastReadPage / widget.book.totalPages
        : 0.0;

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
                          : const Color(0xFFD4AF37).withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    if (!isDark)
                      BoxShadow(
                        color:
                            const Color(0xFFD4AF37).withValues(alpha: 0.06),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _loading
                          ? Container(
                              color: isDark
                                  ? const Color(0xFF141414)
                                  : const Color(0xFFF5F0E8),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark
                                        ? const Color(0xFFD4AF37)
                                        : const Color(0xFFB8941F),
                                  ),
                                ),
                              ),
                            )
                          : _thumbnail != null
                              ? Image.memory(
                                  _thumbnail!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  color: isDark
                                      ? const Color(0xFF141414)
                                      : const Color(0xFFF5F0E8),
                                  child: Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 40,
                                    color: isDark
                                        ? const Color(0xFFD4AF37)
                                        : const Color(0xFFB8941F),
                                  ),
                                ),
                    ),

                    // Reading progress bar at the bottom
                    if (progress > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFE8E4DC),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Percentage badge
                    if (progress > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A)
                                .withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                    ? const Color(0xFFE5E0D8)
                    : const Color(0xFF2D2D2D),
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
