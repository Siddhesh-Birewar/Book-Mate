import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/bookshelf_screen.dart';

/// Root MaterialApp widget that consumes the [ThemeProvider]
/// for dynamic light/dark theme switching.
class BookMateApp extends StatelessWidget {
  const BookMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Book Mate',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme,
      home: const BookshelfScreen(),
    );
  }
}
