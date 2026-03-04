// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:budget_tracker/main.dart';
import 'package:budget_tracker/providers/transaction_provider.dart';
import 'package:budget_tracker/providers/undo_redo_provider.dart';

void main() {
  testWidgets('Budget Tracker app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // Verify that the app loads with the bottom navigation
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify dashboard loads (multiple "Dashboard" texts are expected)
    expect(find.text('Dashboard'), findsWidgets);
  });
}
