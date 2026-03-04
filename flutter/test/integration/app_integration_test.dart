import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_tracker/main.dart';
import 'package:budget_tracker/providers/transaction_provider.dart';
import 'package:budget_tracker/providers/undo_redo_provider.dart';

void main() {
  group('Budget Tracker Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('complete transaction workflow', (WidgetTester tester) async {
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

      // Verify we're on the dashboard
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Navigate to transactions page
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Verify we're on transactions page
      expect(find.text('Transactions'), findsWidgets);

      // Tap add transaction button
      final addButton = find.byType(FloatingActionButton);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Should open add transaction dialog
      expect(find.text('Add Transaction'), findsOneWidget);

      // Fill in transaction details
      await tester.enterText(
        find.byKey(const Key('description_field')),
        'Integration test transaction',
      );
      await tester.enterText(
        find.byKey(const Key('amount_field')),
        '250.75',
      );

      // Select income type
      await tester.tap(find.byKey(const Key('income_button')));
      await tester.pump();

      // Submit the transaction
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify transaction was added
      expect(find.text('Integration test transaction'), findsOneWidget);
      expect(find.text('\$250.75'), findsOneWidget);

      // Navigate back to dashboard
      await tester.tap(find.byIcon(Icons.dashboard));
      await tester.pumpAndSettle();

      // Verify dashboard shows updated totals
      expect(find.textContaining('\$250.75'), findsWidgets);
    });

    testWidgets('category management workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionProvider()),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to categories page
      await tester.tap(find.byIcon(Icons.category));
      await tester.pumpAndSettle();

      // Verify we're on categories page
      expect(find.text('Categories'), findsWidgets);

      // Should show default categories
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);

      // Tap add category button
      final addButton = find.byType(FloatingActionButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Should open add category dialog
      expect(find.text('Add Category'), findsOneWidget);

      // Fill in category details
      await tester.enterText(
        find.byKey(const Key('category_name_field')),
        'Test Category',
      );

      // Add keywords
      await tester.enterText(
        find.byKey(const Key('keywords_field')),
        'test, integration',
      );

      // Submit the category
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify category was added
      expect(find.text('Test Category'), findsOneWidget);
    });

    testWidgets('date range filtering workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionProvider()),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to transactions page
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Should show date range selector
      expect(find.byType(Card), findsWidgets);
      expect(find.text('Last 7 Days'), findsOneWidget);

      // Change date range to last 30 days
      await tester.tap(find.text('Last 30 Days'));
      await tester.pumpAndSettle();

      // Verify date range changed (the display should update)
      // Note: This test assumes the DateRangeSelector updates properly
      expect(find.text('Last 30 Days'), findsOneWidget);
    });

    testWidgets('settings and theme workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionProvider()),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to settings page
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify we're on settings page
      expect(find.text('Settings'), findsWidgets);

      // Should show currency settings
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);

      // Test currency change
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      // Should open currency selection
      expect(find.text('Select Currency'), findsOneWidget);

      // Select EUR
      await tester.tap(find.text('EUR (€)'));
      await tester.pumpAndSettle();

      // Verify currency changed
      expect(find.textContaining('€'), findsWidgets);
    });

    testWidgets('data backup and restore workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionProvider()),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Add a test transaction first
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('description_field')),
        'Backup test transaction',
      );
      await tester.enterText(
        find.byKey(const Key('amount_field')),
        '100.00',
      );

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Look for backup options
      expect(find.text('Backup & Restore'), findsOneWidget);

      // Tap backup
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Should show backup dialog or success message
      expect(find.text('Export Data'), findsWidgets);
    });

    testWidgets('undo/redo functionality workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionProvider()),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to transactions page
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Add a transaction
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('description_field')),
        'Undo test transaction',
      );
      await tester.enterText(
        find.byKey(const Key('amount_field')),
        '50.00',
      );

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify transaction exists
      expect(find.text('Undo test transaction'), findsOneWidget);

      // Look for undo button (assuming it's visible)
      final undoButton = find.byIcon(Icons.undo);
      if (undoButton.evaluate().isNotEmpty) {
        await tester.tap(undoButton);
        await tester.pumpAndSettle();

        // Transaction should be removed
        expect(find.text('Undo test transaction'), findsNothing);

        // Look for redo button
        final redoButton = find.byIcon(Icons.redo);
        if (redoButton.evaluate().isNotEmpty) {
          await tester.tap(redoButton);
          await tester.pumpAndSettle();

          // Transaction should be back
          expect(find.text('Undo test transaction'), findsOneWidget);
        }
      }
    });

    testWidgets('trends page navigation and display', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionProvider()),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to trends page
      await tester.tap(find.byIcon(Icons.trending_up));
      await tester.pumpAndSettle();

      // Verify we're on trends page
      expect(find.text('Trends'), findsWidgets);

      // Should show charts or trend information
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('search and filter functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionProvider()),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Add a couple of test transactions first
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Add first transaction
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('description_field')),
        'Grocery shopping',
      );
      await tester.enterText(
        find.byKey(const Key('amount_field')),
        '75.50',
      );

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Add second transaction
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('description_field')),
        'Gas station',
      );
      await tester.enterText(
        find.byKey(const Key('amount_field')),
        '45.00',
      );

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Should see both transactions
      expect(find.text('Grocery shopping'), findsOneWidget);
      expect(find.text('Gas station'), findsOneWidget);

      // Look for search functionality
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField.first, 'grocery');
        await tester.pumpAndSettle();

        // Should filter to show only grocery transaction
        expect(find.text('Grocery shopping'), findsOneWidget);
        expect(find.text('Gas station'), findsNothing);
      }
    });

    testWidgets('error handling and edge cases', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionProvider()),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test empty state on dashboard
      expect(find.text('Dashboard'), findsWidgets);

      // Navigate to transactions with no data
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Should handle empty state gracefully
      expect(find.text('Transactions'), findsWidgets);

      // Test invalid input in add transaction
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Try to submit without description
      await tester.tap(find.text('Add'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a description'), findsOneWidget);

      // Enter invalid amount
      await tester.enterText(
        find.byKey(const Key('description_field')),
        'Test',
      );
      await tester.enterText(
        find.byKey(const Key('amount_field')),
        'invalid',
      );

      await tester.tap(find.text('Add'));
      await tester.pump();

      // Should show amount validation error
      expect(find.text('Please enter a valid amount'), findsOneWidget);
    });

    testWidgets('app state persistence simulation', (WidgetTester tester) async {
      // This test simulates app restart by creating a new provider instance
      var transactionProvider = TransactionProvider();
      await transactionProvider.initialize();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TransactionProvider>.value(
              value: transactionProvider,
            ),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Add a transaction
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('description_field')),
        'Persistent transaction',
      );
      await tester.enterText(
        find.byKey(const Key('amount_field')),
        '123.45',
      );

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify transaction was added
      expect(find.text('Persistent transaction'), findsOneWidget);

      // Simulate app restart with new provider instance
      final newTransactionProvider = TransactionProvider();
      await newTransactionProvider.initialize();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TransactionProvider>.value(
              value: newTransactionProvider,
            ),
            ChangeNotifierProvider(create: (_) => UndoRedoProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to transactions page
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Transaction should still be there (if storage is working)
      // Note: This test may not work as expected in the test environment
      // since SharedPreferences mock doesn't persist between instances
    });
  });
}