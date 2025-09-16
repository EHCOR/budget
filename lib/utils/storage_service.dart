// utils/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class StorageService {
  static const String _transactionsKey = 'budget_tracker_transactions';
  static const String _categoriesKey = 'budget_tracker_categories';
  static const String _settingsKey = 'budget_tracker_settings';

  // Save transactions
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(transactions.map((t) => t.toJson()).toList());
      await prefs.setString(_transactionsKey, json);
    } catch (e) {
      print('Error saving transactions: $e');
    }
  }

  // Load transactions
  static Future<List<Transaction>> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_transactionsKey);
      if (json == null || json.isEmpty) return [];

      final list = jsonDecode(json) as List;
      return list.map((item) => Transaction.fromJson(item)).toList();
    } catch (e) {
      print('Error loading transactions: $e');
      return [];
    }
  }

  // Save categories
  static Future<void> saveCategories(List<Category> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(categories.map((c) => c.toJson()).toList());
      await prefs.setString(_categoriesKey, json);
    } catch (e) {
      print('Error saving categories: $e');
    }
  }

  // Load categories
  static Future<List<Category>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_categoriesKey);
      if (json == null || json.isEmpty) {
        // Return default categories if none saved
        return Category.getDefaultCategories();
      }

      final list = jsonDecode(json) as List;
      return list.map((item) => Category.fromJson(item)).toList();
    } catch (e) {
      print('Error loading categories: $e');
      return Category.getDefaultCategories();
    }
  }

  // Save settings
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings));
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  // Load settings
  static Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_settingsKey);
      if (json == null || json.isEmpty) {
        return {
          'currencyCode': 'USD',
          'currencySymbol': '\$',
          'themeMode': 'system',
        };
      }
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading settings: $e');
      return {
        'currencyCode': 'USD',
        'currencySymbol': '\$',
        'themeMode': 'system',
      };
    }
  }

  // Clear all data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_transactionsKey);
      await prefs.remove(_categoriesKey);
      // Keep settings
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Export data as JSON string (for backup)
  static Future<String> exportData() async {
    try {
      final transactions = await loadTransactions();
      final categories = await loadCategories();
      final settings = await loadSettings();

      final data = {
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'settings': settings,
        'exportDate': DateTime.now().toIso8601String(),
      };

      return jsonEncode(data);
    } catch (e) {
      print('Error exporting data: $e');
      return '';
    }
  }

  // Import data from JSON string
  static Future<bool> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import transactions
      if (data.containsKey('transactions')) {
        final list = data['transactions'] as List;
        final transactions = list.map((item) => Transaction.fromJson(item)).toList();
        await saveTransactions(transactions);
      }

      // Import categories
      if (data.containsKey('categories')) {
        final list = data['categories'] as List;
        final categories = list.map((item) => Category.fromJson(item)).toList();
        await saveCategories(categories);
      }

      // Import settings
      if (data.containsKey('settings')) {
        await saveSettings(data['settings'] as Map<String, dynamic>);
      }

      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
}