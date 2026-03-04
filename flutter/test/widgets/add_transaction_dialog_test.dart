import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_tracker/widgets/add_transaction_dialog.dart';
import 'package:budget_tracker/providers/transaction_provider.dart';
import 'package:budget_tracker/providers/undo_redo_provider.dart';
import 'package:budget_tracker/models/transaction.dart';

void main() {
  group('AddTransactionDialog Widget Tests', () {
    late TransactionProvider transactionProvider;
    late UndoRedoProvider undoRedoProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      transactionProvider = TransactionProvider();
      undoRedoProvider = UndoRedoProvider();
      await transactionProvider.initialize();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>.value(
                value: transactionProvider,
              ),
              ChangeNotifierProvider<UndoRedoProvider>.value(
                value: undoRedoProvider,
              ),
            ],
            child: const AddTransactionDialog(),
          ),
        ),
      );
    }

    testWidgets('displays dialog with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('shows all required form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show description field
      expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget);

      // Should show amount field
      expect(find.widgetWithText(TextFormField, 'Amount'), findsOneWidget);

      // Should show transaction type selector
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);

      // Should show category dropdown
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Should show date selector with Date label
      expect(find.text('Date'), findsOneWidget);

      // Should show action buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('description field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final descriptionField = find.widgetWithText(TextFormField, 'Description');
      await tester.enterText(descriptionField, 'Test transaction');
      await tester.pump();

      expect(find.text('Test transaction'), findsOneWidget);
    });

    testWidgets('amount field accepts numeric input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final amountField = find.widgetWithText(TextFormField, 'Amount');
      await tester.enterText(amountField, '123.45');
      await tester.pump();

      expect(find.text('123.45'), findsOneWidget);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Try to submit without filling fields
      await tester.tap(find.text('Add'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter a description'), findsOneWidget);
      expect(find.text('Please enter an amount'), findsOneWidget);
    });

    testWidgets('validates amount field properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final amountField = find.widgetWithText(TextFormField, 'Amount');

      // Test invalid amount
      await tester.enterText(amountField, 'invalid');
      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(find.text('Please enter a valid amount'), findsOneWidget);

      // Test zero amount
      await tester.enterText(amountField, '0');
      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(find.text('Amount must be greater than 0'), findsOneWidget);

      // Test negative amount
      await tester.enterText(amountField, '-50');
      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(find.text('Amount must be greater than 0'), findsOneWidget);
    });

    testWidgets('transaction type selector works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Default should be expense
      final expenseButton = find.widgetWithText(RadioListTile<TransactionType>, 'Expense');
      final incomeButton = find.widgetWithText(RadioListTile<TransactionType>, 'Income');

      // Expense should be selected by default
      expect(tester.widget<ElevatedButton>(expenseButton).style?.backgroundColor?.resolve({}),
             isNot(null));

      // Tap income
      await tester.tap(incomeButton);
      await tester.pump();

      // Income should now be selected
      expect(tester.widget<ElevatedButton>(incomeButton).style?.backgroundColor?.resolve({}),
             isNot(null));
    });

    testWidgets('category dropdown shows available categories', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show default categories
      expect(find.text('Uncategorized'), findsWidgets);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
    });

    testWidgets('date selector shows current date by default', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final dateSelector = find.widgetWithText(InputDecorator, 'Date');
      expect(dateSelector, findsOneWidget);

      // Should show today's date
      final today = DateTime.now();
      final formattedDate = '${today.day}/${today.month}/${today.year}';
      expect(find.textContaining(formattedDate), findsOneWidget);
    });

    testWidgets('date picker opens when date selector is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.widgetWithText(InputDecorator, 'Date'));
      await tester.pumpAndSettle();

      // Should open date picker
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed (test runner will verify this)
      expect(find.byType(AddTransactionDialog), findsNothing);
    });

    testWidgets('successfully adds transaction with valid data', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Fill in form fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Test transaction');
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '100.50');

      // Select income type
      await tester.tap(find.widgetWithText(RadioListTile<TransactionType>, 'Income'));
      await tester.pump();

      // Select a category
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();

      final initialTransactionCount = transactionProvider.transactions.length;

      // Submit form
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Should have added a transaction
      expect(transactionProvider.transactions.length, initialTransactionCount + 1);

      final addedTransaction = transactionProvider.transactions.last;
      expect(addedTransaction.description, 'Test transaction');
      expect(addedTransaction.amount, 100.50);
      expect(addedTransaction.type, TransactionType.income);
    });

    testWidgets('handles decimal amounts correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Decimal test');
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '99.99');

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final addedTransaction = transactionProvider.transactions.last;
      expect(addedTransaction.amount, 99.99);
    });

    testWidgets('handles large amounts correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Large amount');
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '1000000.00');

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final addedTransaction = transactionProvider.transactions.last;
      expect(addedTransaction.amount, 1000000.00);
    });

    testWidgets('preserves category selection across type changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Select a category
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();

      // Change transaction type
      await tester.tap(find.widgetWithText(RadioListTile<TransactionType>, 'Income'));
      await tester.pump();

      // Category should still be selected
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('resets form after successful submission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Fill form
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Test');
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '100');

      // Submit
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Form should be reset
      expect(find.text('Test'), findsNothing);
      expect(find.text('100'), findsNothing);
    });

    testWidgets('maintains focus management properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Focus should start on description field
      final descriptionField = find.widgetWithText(TextFormField, 'Description');
      await tester.tap(descriptionField);
      await tester.pump();

      expect(Focus.of(tester.element(descriptionField)).hasFocus, true);
    });

    testWidgets('handles keyboard input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final descriptionField = find.widgetWithText(TextFormField, 'Description');
      await tester.tap(descriptionField);

      // Simulate typing
      await tester.enterText(descriptionField, 'test');
      await tester.pump();

      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('shows proper currency symbol in amount field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final amountField = find.widgetWithText(TextFormField, 'Amount');
      expect(amountField, findsOneWidget);

      // Should show currency symbol (default is $)
      expect(find.textContaining('\$'), findsOneWidget);
    });

    testWidgets('updates currency symbol when provider changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Change currency
      await transactionProvider.setCurrency('EUR', '€');
      await tester.pump();

      // Should now show Euro symbol
      expect(find.textContaining('€'), findsOneWidget);
    });
  });
}