import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/utils/storage_service.dart';
import 'package:budget_tracker/models/transaction.dart';
import 'package:budget_tracker/models/category.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('Backup and Restore Tests', () {
    setUpAll(() {
      // Set up SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    test('Export and import transactions', () async {
      // Create test transactions
      final testTransactions = [
        Transaction(
          id: 'test1',
          description: 'Test transaction 1',
          amount: 100.0,
          date: DateTime.now(),
          type: TransactionType.expense,
          categoryId: 'food',
        ),
        Transaction(
          id: 'test2',
          description: 'Test transaction 2',
          amount: 50.0,
          date: DateTime.now(),
          type: TransactionType.income,
          categoryId: 'salary',
        ),
      ];

      // Save transactions
      await StorageService.saveTransactions(testTransactions);

      // Export data
      final exportedData = await StorageService.exportData();
      expect(exportedData.isNotEmpty, true);

      // Verify exported data structure
      final decodedData = jsonDecode(exportedData) as Map<String, dynamic>;
      expect(decodedData.containsKey('transactions'), true);
      expect(decodedData.containsKey('categories'), true);
      expect(decodedData.containsKey('settings'), true);
      expect(decodedData.containsKey('exportDate'), true);

      // Verify transactions in export
      final exportedTransactions = decodedData['transactions'] as List;
      expect(exportedTransactions.length, 2);
      expect(exportedTransactions[0]['id'], 'test1');
      expect(exportedTransactions[1]['id'], 'test2');

      // Clear data
      await StorageService.clearAllData();

      // Verify data is cleared
      final clearedTransactions = await StorageService.loadTransactions();
      expect(clearedTransactions.isEmpty, true);

      // Import data back
      final importSuccess = await StorageService.importData(exportedData);
      expect(importSuccess, true);

      // Verify transactions are restored
      final restoredTransactions = await StorageService.loadTransactions();
      expect(restoredTransactions.length, 2);
      expect(restoredTransactions[0].id, 'test1');
      expect(restoredTransactions[1].id, 'test2');
      expect(restoredTransactions[0].description, 'Test transaction 1');
      expect(restoredTransactions[1].description, 'Test transaction 2');
    });

    test('Export and import categories', () async {
      // Create test categories
      final testCategories = [
        Category(
          id: 'custom1',
          name: 'Custom Category 1',
          color: Colors.red,
          icon: Icons.category,
          keywords: ['keyword1', 'keyword2'],
        ),
        Category(
          id: 'custom2',
          name: 'Custom Category 2',
          color: Colors.blue,
          icon: Icons.money,
          keywords: ['keyword3'],
        ),
      ];

      // Save categories
      await StorageService.saveCategories(testCategories);

      // Export data
      final exportedData = await StorageService.exportData();
      final decodedData = jsonDecode(exportedData) as Map<String, dynamic>;

      // Verify categories in export
      final exportedCategories = decodedData['categories'] as List;
      expect(exportedCategories.length, 2);
      expect(exportedCategories[0]['id'], 'custom1');
      expect(exportedCategories[1]['id'], 'custom2');

      // Clear data and import back
      await StorageService.clearAllData();
      final importSuccess = await StorageService.importData(exportedData);
      expect(importSuccess, true);

      // Verify categories are restored
      final restoredCategories = await StorageService.loadCategories();
      // Note: loadCategories returns default categories if empty, so we need to check if our custom ones are there
      final customCategories = restoredCategories.where((c) => c.id.startsWith('custom')).toList();
      expect(customCategories.length, 2);
      expect(customCategories[0].name, 'Custom Category 1');
      expect(customCategories[1].name, 'Custom Category 2');
    });

    test('Export and import settings', () async {
      // Create test settings
      final testSettings = {
        'currencyCode': 'EUR',
        'currencySymbol': '€',
        'themeMode': 'dark',
      };

      // Save settings
      await StorageService.saveSettings(testSettings);

      // Export data
      final exportedData = await StorageService.exportData();
      final decodedData = jsonDecode(exportedData) as Map<String, dynamic>;

      // Verify settings in export
      final exportedSettings = decodedData['settings'] as Map<String, dynamic>;
      expect(exportedSettings['currencyCode'], 'EUR');
      expect(exportedSettings['currencySymbol'], '€');
      expect(exportedSettings['themeMode'], 'dark');

      // Clear and import back
      SharedPreferences.setMockInitialValues({});
      final importSuccess = await StorageService.importData(exportedData);
      expect(importSuccess, true);

      // Verify settings are restored
      final restoredSettings = await StorageService.loadSettings();
      expect(restoredSettings['currencyCode'], 'EUR');
      expect(restoredSettings['currencySymbol'], '€');
      expect(restoredSettings['themeMode'], 'dark');
    });

    test('Import handles invalid JSON gracefully', () async {
      final invalidJson = 'invalid json string';
      final importSuccess = await StorageService.importData(invalidJson);
      expect(importSuccess, false);
    });

    test('Import handles partial data correctly', () async {
      // Create export with only transactions
      final partialData = {
        'transactions': [
          {
            'id': 'partial1',
            'description': 'Partial test',
            'amount': 25.0,
            'date': DateTime.now().toIso8601String(),
            'type': 'expense',
            'categoryId': 'food',
          }
        ],
        'exportDate': DateTime.now().toIso8601String(),
      };

      final partialJson = jsonEncode(partialData);
      final importSuccess = await StorageService.importData(partialJson);
      expect(importSuccess, true);

      // Verify only transactions were imported
      final transactions = await StorageService.loadTransactions();
      expect(transactions.length, 1);
      expect(transactions[0].id, 'partial1');
    });

    test('Full backup and restore workflow', () async {
      // Create comprehensive test data
      final transactions = [
        Transaction(
          id: 'workflow1',
          description: 'Workflow transaction 1',
          amount: 200.0,
          date: DateTime.now(),
          type: TransactionType.expense,
          categoryId: 'entertainment',
        ),
        Transaction(
          id: 'workflow2',
          description: 'Workflow transaction 2',
          amount: 150.0,
          date: DateTime.now().subtract(Duration(days: 1)),
          type: TransactionType.income,
          categoryId: 'freelance',
        ),
      ];

      final categories = [
        Category(
          id: 'workflow_cat',
          name: 'Workflow Category',
          color: Colors.purple,
          icon: Icons.work,
          keywords: ['workflow', 'test'],
        ),
      ];

      final settings = {
        'currencyCode': 'GBP',
        'currencySymbol': '£',
        'themeMode': 'light',
      };

      // Save all data
      await StorageService.saveTransactions(transactions);
      await StorageService.saveCategories(categories);
      await StorageService.saveSettings(settings);

      // Export everything
      final backupData = await StorageService.exportData();
      expect(backupData.isNotEmpty, true);

      // Verify export contains all data
      final exportJson = jsonDecode(backupData) as Map<String, dynamic>;
      expect((exportJson['transactions'] as List).length, 2);
      expect((exportJson['categories'] as List).length, 1);
      expect(exportJson['settings']['currencyCode'], 'GBP');

      // Clear everything
      await StorageService.clearAllData();
      SharedPreferences.setMockInitialValues({});

      // Verify everything is cleared
      expect((await StorageService.loadTransactions()).isEmpty, true);
      expect(await StorageService.loadSettings(), isA<Map<String, dynamic>>());

      // Restore from backup
      final restoreSuccess = await StorageService.importData(backupData);
      expect(restoreSuccess, true);

      // Verify everything is restored correctly
      final restoredTransactions = await StorageService.loadTransactions();
      final restoredCategories = await StorageService.loadCategories();
      final restoredSettings = await StorageService.loadSettings();

      expect(restoredTransactions.length, 2);
      expect(restoredTransactions.any((t) => t.id == 'workflow1'), true);
      expect(restoredTransactions.any((t) => t.id == 'workflow2'), true);

      expect(restoredCategories.any((c) => c.id == 'workflow_cat'), true);

      expect(restoredSettings['currencyCode'], 'GBP');
      expect(restoredSettings['currencySymbol'], '£');
      expect(restoredSettings['themeMode'], 'light');
    });
  });
}