import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_tracker/providers/transaction_provider.dart';
import 'package:budget_tracker/models/transaction.dart';
import 'package:budget_tracker/models/category.dart';

void main() {
  group('TransactionProvider Tests', () {
    late TransactionProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = TransactionProvider();
    });

    group('Basic functionality', () {
      test('initial state is empty', () {
        expect(provider.transactions, isEmpty);
        expect(provider.categories, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.totalIncome, 0.0);
        expect(provider.totalExpenses, 0.0);
        expect(provider.netCashFlow, 0.0);
      });

      test('initialize loads default categories', () async {
        await provider.initialize();
        expect(provider.categories, isNotEmpty);
        expect(provider.isLoading, false);
      });

      test('setDateRange updates date range and notifies listeners', () {
        bool notified = false;
        provider.addListener(() => notified = true);

        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 12, 31);
        provider.setDateRange(startDate, endDate);

        expect(provider.startDate, startDate);
        expect(provider.endDate, endDate);
        expect(notified, true);
      });
    });

    group('Transaction management', () {
      test('addTransaction adds transaction and notifies listeners', () async {
        await provider.initialize();
        bool notified = false;
        provider.addListener(() => notified = true);

        final transaction = Transaction(
          date: DateTime.now(),
          description: 'Test transaction',
          amount: 100.0,
        );

        await provider.addTransaction(transaction);

        expect(provider.transactions, contains(transaction));
        expect(notified, true);
      });

      test('updateTransaction modifies existing transaction', () async {
        await provider.initialize();

        final transaction = Transaction(
          date: DateTime.now(),
          description: 'Original',
          amount: 100.0,
        );
        await provider.addTransaction(transaction);

        final updatedTransaction = transaction.copyWith(
          description: 'Updated',
          amount: 200.0,
        );

        await provider.updateTransaction(updatedTransaction);

        final found = provider.getTransactionById(transaction.id);
        expect(found!.description, 'Updated');
        expect(found.amount, 200.0);
      });

      test('deleteTransaction removes transaction', () async {
        await provider.initialize();

        final transaction = Transaction(
          date: DateTime.now(),
          description: 'To be deleted',
          amount: 100.0,
        );
        await provider.addTransaction(transaction);
        expect(provider.transactions, contains(transaction));

        await provider.deleteTransaction(transaction.id);
        expect(provider.transactions, isNot(contains(transaction)));
      });

      test('updateTransactionCategory changes category', () async {
        await provider.initialize();

        final transaction = Transaction(
          date: DateTime.now(),
          description: 'Test',
          amount: 100.0,
          categoryId: 'uncategorized',
        );
        await provider.addTransaction(transaction);

        await provider.updateTransactionCategory(transaction.id, 'food');

        final found = provider.getTransactionById(transaction.id);
        expect(found!.categoryId, 'food');
      });
    });

    group('Duplicate detection', () {
      test('addTransactions detects duplicates correctly', () async {
        await provider.initialize();

        final date = DateTime(2024, 1, 15);
        final existingTransaction = Transaction(
          date: date,
          description: 'Existing transaction',
          amount: 100.0,
        );
        await provider.addTransaction(existingTransaction);

        final newTransactions = [
          Transaction(
            date: date,
            description: 'Existing transaction', // Same as existing
            amount: 100.0,
          ),
          Transaction(
            date: date,
            description: 'New transaction',
            amount: 200.0,
          ),
        ];

        final result = await provider.addTransactions(newTransactions);

        expect(result['imported'], 1); // Only one new transaction
        expect(result['duplicates'], 1); // One duplicate detected
        expect(result['total'], 2); // Total transactions processed
      });

      test('duplicate detection considers date, amount, and description', () async {
        await provider.initialize();

        final baseDate = DateTime(2024, 1, 15);
        final baseTransaction = Transaction(
          date: baseDate,
          description: 'Base transaction',
          amount: 100.0,
        );
        await provider.addTransaction(baseTransaction);

        // Different date - not duplicate
        final differentDate = Transaction(
          date: baseDate.add(Duration(days: 1)),
          description: 'Base transaction',
          amount: 100.0,
        );

        // Different amount - not duplicate
        final differentAmount = Transaction(
          date: baseDate,
          description: 'Base transaction',
          amount: 200.0,
        );

        // Different description - not duplicate
        final differentDescription = Transaction(
          date: baseDate,
          description: 'Different transaction',
          amount: 100.0,
        );

        final result = await provider.addTransactions([
          differentDate,
          differentAmount,
          differentDescription,
        ]);

        expect(result['imported'], 3); // All should be imported
        expect(result['duplicates'], 0); // No duplicates
      });
    });

    group('Categorization logic', () {
      test('auto-categorizes transactions based on keywords', () async {
        await provider.initialize();

        // Add a category with keywords
        final foodCategory = Category(
          id: 'food',
          name: 'Food',
          color: Colors.red,
          icon: Icons.restaurant,
          keywords: ['restaurant', 'grocery', 'food'],
        );
        await provider.addCategory(foodCategory);

        final transactions = [
          Transaction(
            date: DateTime.now(),
            description: 'McDonald\'s restaurant',
            amount: 15.0,
          ),
          Transaction(
            date: DateTime.now(),
            description: 'Walmart grocery store',
            amount: 50.0,
          ),
          Transaction(
            date: DateTime.now(),
            description: 'Gas station',
            amount: 30.0,
          ),
        ];

        await provider.addTransactions(transactions);

        final foodTransactions = provider.getTransactionsByCategory('food');
        expect(foodTransactions.length, 2); // Restaurant and grocery should be categorized

        final uncategorized = provider.uncategorizedTransactions;
        expect(uncategorized.length, 1); // Gas station should remain uncategorized
      });

      test('countTransactionsByKeywords counts correctly', () async {
        await provider.initialize();

        final transactions = [
          Transaction(
            date: DateTime.now(),
            description: 'Restaurant meal',
            amount: 25.0,
            categoryId: 'uncategorized',
          ),
          Transaction(
            date: DateTime.now(),
            description: 'Grocery shopping',
            amount: 100.0,
            categoryId: 'uncategorized',
          ),
          Transaction(
            date: DateTime.now(),
            description: 'Gas station',
            amount: 50.0,
            categoryId: 'uncategorized',
          ),
        ];

        for (var transaction in transactions) {
          await provider.addTransaction(transaction);
        }

        final count = provider.countTransactionsByKeywords(['restaurant', 'grocery']);
        expect(count, 2); // Should match restaurant and grocery transactions
      });

      test('recategorizeTransactionsByKeywords updates categories', () async {
        await provider.initialize();

        final transactions = [
          Transaction(
            date: DateTime.now(),
            description: 'Restaurant meal',
            amount: 25.0,
            categoryId: 'uncategorized',
          ),
          Transaction(
            date: DateTime.now(),
            description: 'Gas station',
            amount: 50.0,
            categoryId: 'uncategorized',
          ),
        ];

        for (var transaction in transactions) {
          await provider.addTransaction(transaction);
        }

        final count = await provider.recategorizeTransactionsByKeywords(
          'food',
          ['restaurant'],
        );

        expect(count, 1); // Only restaurant transaction should be recategorized

        final foodTransactions = provider.getTransactionsByCategory('food');
        expect(foodTransactions.length, 1);
        expect(foodTransactions.first.description, 'Restaurant meal');
      });
    });

    group('Category management', () {
      test('addCategory adds category and notifies listeners', () async {
        await provider.initialize();
        bool notified = false;
        provider.addListener(() => notified = true);

        final category = Category(
          id: 'test',
          name: 'Test Category',
          color: Colors.blue,
          icon: Icons.category,
          keywords: ['test'],
        );

        await provider.addCategory(category);

        expect(provider.categories, contains(category));
        expect(notified, true);
      });

      test('updateCategory modifies existing category', () async {
        await provider.initialize();

        final category = Category(
          id: 'test',
          name: 'Original',
          color: Colors.blue,
          icon: Icons.category,
          keywords: ['original'],
        );
        await provider.addCategory(category);

        final updatedCategory = Category(
          id: 'test',
          name: 'Updated',
          color: Colors.red,
          icon: Icons.update,
          keywords: ['updated'],
        );

        await provider.updateCategory(updatedCategory);

        final found = provider.getCategoryById('test');
        expect(found!.name, 'Updated');
        expect(found.color, Colors.red);
      });

      test('deleteCategory moves transactions to uncategorized', () async {
        await provider.initialize();

        final category = Category(
          id: 'test',
          name: 'Test Category',
          color: Colors.blue,
          icon: Icons.category,
          keywords: ['test'],
        );
        await provider.addCategory(category);

        final transaction = Transaction(
          date: DateTime.now(),
          description: 'Test transaction',
          amount: 100.0,
          categoryId: 'test',
        );
        await provider.addTransaction(transaction);

        await provider.deleteCategory('test');

        expect(provider.getCategoryById('test'), isNull);

        final updatedTransaction = provider.getTransactionById(transaction.id);
        expect(updatedTransaction!.categoryId, 'uncategorized');
      });

      test('calculateCategoryChanges predicts impact correctly', () async {
        await provider.initialize();

        // Create category and transactions
        final category = Category(
          id: 'test',
          name: 'Test',
          color: Colors.blue,
          icon: Icons.category,
          keywords: ['old'],
        );
        await provider.addCategory(category);

        final transactions = [
          Transaction(
            date: DateTime.now(),
            description: 'old keyword transaction',
            amount: 50.0,
            categoryId: 'test',
          ),
          Transaction(
            date: DateTime.now(),
            description: 'new keyword transaction',
            amount: 75.0,
            categoryId: 'uncategorized',
          ),
          Transaction(
            date: DateTime.now(),
            description: 'unrelated transaction',
            amount: 100.0,
            categoryId: 'uncategorized',
          ),
        ];

        for (var transaction in transactions) {
          await provider.addTransaction(transaction);
        }

        // Calculate changes for new keywords
        final changes = provider.calculateCategoryChanges(category, ['new']);

        expect(changes['removed'], 1); // Old keyword transaction will be removed
        expect(changes['added'], 1); // New keyword transaction will be added
      });

      test('updateCategoryAndRecategorize applies changes', () async {
        await provider.initialize();

        final category = Category(
          id: 'test',
          name: 'Test',
          color: Colors.blue,
          icon: Icons.category,
          keywords: ['old'],
        );
        await provider.addCategory(category);

        final transactions = [
          Transaction(
            date: DateTime.now(),
            description: 'old keyword transaction',
            amount: 50.0,
            categoryId: 'test',
          ),
          Transaction(
            date: DateTime.now(),
            description: 'new keyword transaction',
            amount: 75.0,
            categoryId: 'uncategorized',
          ),
        ];

        for (var transaction in transactions) {
          await provider.addTransaction(transaction);
        }

        final result = await provider.updateCategoryAndRecategorize(
          category,
          ['new'],
        );

        expect(result['removed'], 1);
        expect(result['added'], 1);

        final categoryTransactions = provider.getTransactionsByCategory('test');
        expect(categoryTransactions.length, 1);
        expect(categoryTransactions.first.description, 'new keyword transaction');
      });
    });

    group('Financial calculations', () {
      test('calculates totals correctly', () async {
        await provider.initialize();

        final transactions = [
          Transaction(
            date: DateTime.now(),
            description: 'Income',
            amount: 1000.0,
            type: TransactionType.income,
          ),
          Transaction(
            date: DateTime.now(),
            description: 'Expense',
            amount: 300.0,
            type: TransactionType.expense,
          ),
          Transaction(
            date: DateTime.now(),
            description: 'Another expense',
            amount: 200.0,
            type: TransactionType.expense,
          ),
        ];

        for (var transaction in transactions) {
          await provider.addTransaction(transaction);
        }

        expect(provider.totalIncome, 1000.0);
        expect(provider.totalExpenses, 500.0);
        expect(provider.netCashFlow, 500.0);
      });

      test('getCategorySummaries groups by category', () async {
        await provider.initialize();

        final transactions = [
          Transaction(
            date: DateTime.now(),
            description: 'Food 1',
            amount: 50.0,
            categoryId: 'food',
            type: TransactionType.expense,
          ),
          Transaction(
            date: DateTime.now(),
            description: 'Food 2',
            amount: 75.0,
            categoryId: 'food',
            type: TransactionType.expense,
          ),
          Transaction(
            date: DateTime.now(),
            description: 'Transport',
            amount: 25.0,
            categoryId: 'transport',
            type: TransactionType.expense,
          ),
        ];

        for (var transaction in transactions) {
          await provider.addTransaction(transaction);
        }

        final summaries = provider.getCategorySummaries();
        expect(summaries.length, 2);

        final foodSummary = summaries.firstWhere((s) => s.categoryId == 'food');
        expect(foodSummary.amount, 125.0); // 50 + 75

        final transportSummary = summaries.firstWhere((s) => s.categoryId == 'transport');
        expect(transportSummary.amount, 25.0);
      });

      test('getMonthlyStats calculates monthly data', () async {
        await provider.initialize();

        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 15);

        final transactions = [
          Transaction(
            date: now,
            description: 'Current month income',
            amount: 1000.0,
            type: TransactionType.income,
          ),
          Transaction(
            date: now,
            description: 'Current month expense',
            amount: 300.0,
            type: TransactionType.expense,
          ),
          Transaction(
            date: lastMonth,
            description: 'Last month income',
            amount: 800.0,
            type: TransactionType.income,
          ),
        ];

        for (var transaction in transactions) {
          await provider.addTransaction(transaction);
        }

        final stats = provider.getMonthlyStats(2);
        expect(stats.length, 2);
        expect(stats.values.every((month) => month.containsKey('income')), true);
        expect(stats.values.every((month) => month.containsKey('expenses')), true);
        expect(stats.values.every((month) => month.containsKey('net')), true);
      });
    });

    group('Settings management', () {
      test('setCurrency updates currency settings', () async {
        await provider.initialize();
        bool notified = false;
        provider.addListener(() => notified = true);

        await provider.setCurrency('EUR', '€');

        expect(provider.currencyCode, 'EUR');
        expect(provider.currencySymbol, '€');
        expect(notified, true);
      });

      test('setThemeMode updates theme setting', () async {
        await provider.initialize();
        bool notified = false;
        provider.addListener(() => notified = true);

        await provider.setThemeMode(ThemeMode.dark);

        expect(provider.themeMode, ThemeMode.dark);
        expect(notified, true);
      });
    });

    group('Command pattern for undo/redo', () {
      test('createAddTransactionCommand creates proper command', () async {
        await provider.initialize();

        final transaction = Transaction(
          date: DateTime.now(),
          description: 'Test',
          amount: 100.0,
        );

        final command = provider.createAddTransactionCommand(transaction);

        expect(command.transactionId, transaction.id);
        expect(command.transactionData, transaction.toJson());
      });

      test('createDeleteTransactionCommand creates proper command', () async {
        await provider.initialize();

        final transaction = Transaction(
          date: DateTime.now(),
          description: 'Test',
          amount: 100.0,
        );
        await provider.addTransaction(transaction);

        final command = provider.createDeleteTransactionCommand(transaction.id);

        expect(command.transactionId, transaction.id);
        expect(command.transactionData, transaction.toJson());
      });

      test('createUpdateTransactionCommand creates proper command', () async {
        await provider.initialize();

        final oldTransaction = Transaction(
          date: DateTime.now(),
          description: 'Old',
          amount: 100.0,
        );

        final newTransaction = oldTransaction.copyWith(
          description: 'New',
          amount: 200.0,
        );

        final command = provider.createUpdateTransactionCommand(
          oldTransaction,
          newTransaction,
        );

        expect(command.transactionId, newTransaction.id);
        expect(command.oldData, oldTransaction.toJson());
        expect(command.newData, newTransaction.toJson());
      });
    });

    group('Data import/export', () {
      test('exportDataAsJson returns valid JSON', () async {
        await provider.initialize();

        final transaction = Transaction(
          date: DateTime.now(),
          description: 'Test',
          amount: 100.0,
        );
        await provider.addTransaction(transaction);

        final jsonData = await provider.exportDataAsJson();
        expect(jsonData, isNotEmpty);
        expect(jsonData, contains('transactions'));
        expect(jsonData, contains('categories'));
        expect(jsonData, contains('settings'));
      });

      test('importDataFromJson imports valid data', () async {
        await provider.initialize();

        // First export some data
        final transaction = Transaction(
          date: DateTime.now(),
          description: 'Test export',
          amount: 150.0,
        );
        await provider.addTransaction(transaction);

        final exportedData = await provider.exportDataAsJson();

        // Clear data
        await provider.clearAllData();
        expect(provider.transactions, isEmpty);

        // Import data back
        final success = await provider.importDataFromJson(exportedData);
        expect(success, true);
        expect(provider.transactions, isNotEmpty);
        expect(provider.transactions.first.description, 'Test export');
      });
    });

    group('Edge cases and error handling', () {
      test('handles non-existent transaction gracefully', () {
        expect(provider.getTransactionById('non-existent'), isNull);
      });

      test('handles non-existent category gracefully', () {
        expect(provider.getCategoryById('non-existent'), isNull);
      });

      test('filtered transactions respects date range', () async {
        await provider.initialize();

        final now = DateTime.now();
        final oldTransaction = Transaction(
          date: now.subtract(Duration(days: 100)),
          description: 'Old transaction',
          amount: 100.0,
        );
        final newTransaction = Transaction(
          date: now,
          description: 'New transaction',
          amount: 200.0,
        );

        await provider.addTransaction(oldTransaction);
        await provider.addTransaction(newTransaction);

        // Set date range to last 30 days
        provider.setDateRange(
          now.subtract(Duration(days: 30)),
          now,
        );

        final filtered = provider.filteredTransactions;
        expect(filtered.length, 1);
        expect(filtered.first.description, 'New transaction');
      });

      test('recalculateAllTransactions processes recent transactions only', () async {
        await provider.initialize();

        // Add a category with keywords
        final category = Category(
          id: 'food',
          name: 'Food',
          color: Colors.red,
          icon: Icons.restaurant,
          keywords: ['restaurant'],
        );
        await provider.addCategory(category);

        final now = DateTime.now();
        final oldTransaction = Transaction(
          date: now.subtract(Duration(days: 180)), // Older than 3 months
          description: 'Old restaurant',
          amount: 50.0,
          categoryId: 'uncategorized',
        );
        final recentTransaction = Transaction(
          date: now.subtract(Duration(days: 30)), // Within 3 months
          description: 'Recent restaurant',
          amount: 75.0,
          categoryId: 'uncategorized',
        );

        await provider.addTransaction(oldTransaction);
        await provider.addTransaction(recentTransaction);

        final result = await provider.recalculateAllTransactions(months: 3);

        expect(result['recategorized'], 1); // Only recent transaction should be recategorized
        expect(result['total'], 1); // Only one transaction in the timeframe

        // Verify only recent transaction was recategorized
        final oldUpdated = provider.getTransactionById(oldTransaction.id);
        final recentUpdated = provider.getTransactionById(recentTransaction.id);

        expect(oldUpdated!.categoryId, 'uncategorized'); // Should remain uncategorized
        expect(recentUpdated!.categoryId, 'food'); // Should be recategorized
      });
    });
  });
}