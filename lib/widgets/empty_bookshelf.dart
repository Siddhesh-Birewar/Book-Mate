import 'package:flutter/material.dart';

/// Empty state widget shown when no books have been imported yet.
class EmptyBookshelf extends StatelessWidget {
  const EmptyBookshelf({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated book icon with gradient
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1A1A0A),
                          const Color(0xFF2A2010),
                        ]
                      : [
                          const Color(0xFFFAF5E8),
                          const Color(0xFFF0E8D0),
                        ],
                ),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 52,
                color: isDark
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFFB8941F),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Your bookshelf is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFE5E0D8)
                    : const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Tap the + button to import a PDF\nand start reading',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? const Color(0xFF8A8178)
                    : const Color(0xFF6E6860),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
