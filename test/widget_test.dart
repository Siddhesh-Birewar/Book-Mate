// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';
import 'package:book_mate/app.dart';
import 'package:provider/provider.dart';
import 'package:book_mate/providers/theme_provider.dart';
import 'package:book_mate/providers/bookshelf_provider.dart';

void main() {
  testWidgets('App renders bookshelf screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => BookshelfProvider()),
        ],
        child: const BookMateApp(),
      ),
    );

    // Verify the app renders with the bookshelf title
    expect(find.text('Book Mate'), findsOneWidget);
    // Verify empty state is shown
    expect(find.text('Your bookshelf is empty'), findsOneWidget);
  });
}
