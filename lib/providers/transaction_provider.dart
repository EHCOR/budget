// providers/transaction_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/storage_service.dart';

class TransactionProvider extends ChangeNotifier {
  // State
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  // Settings
  String _currencySymbol = '\$';
  String _currencyCode = 'USD';
  ThemeMode _themeMode = ThemeMode.system;

  // Getters
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;
  ThemeMode get themeMode => _themeMode;

  // Filtered transactions based on date range
  List<Transaction> get filteredTransactions {
    return _transactions.where((t) =>
    t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get uncategorized transactions
  List<Transaction> get uncategorizedTransactions {
    return filteredTransactions.where((t) => t.categoryId == 'uncategorized').toList();
  }

  // Calculate totals
  double get totalIncome {
    return filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  double get totalExpenses {
    return filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  double get netCashFlow => totalIncome - totalExpenses;

  // Get category summaries
  List<CategorySummary> getCategorySummaries({bool incomeOnly = false}) {
    final Map<String, double> totals = {};

    for (var transaction in filteredTransactions) {
      if (incomeOnly && transaction.type != TransactionType.income) continue;
      if (!incomeOnly && transaction.type != TransactionType.expense) continue;

      final amount = transaction.amount.abs();
      totals[transaction.categoryId] = (totals[transaction.categoryId] ?? 0) + amount;
    }

    return totals.entries.map((entry) {
      final category = getCategoryById(entry.key);
      return CategorySummary(
        categoryId: entry.key,
        categoryName: category?.name ?? 'Unknown',
        amount: entry.value,
        color: category?.color ?? Colors.grey,
        icon: category?.icon ?? Icons.help_outline,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
  }

  // Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Load data from storage
      _transactions = await StorageService.loadTransactions();
      _categories = await StorageService.loadCategories();

      // Load settings
      final settings = await StorageService.loadSettings();
      _currencyCode = settings['currencyCode'] ?? 'USD';
      _currencySymbol = settings['currencySymbol'] ?? '\$';

      final themeModeString = settings['themeMode'] ?? 'system';
      _themeMode = themeModeString == 'dark'
          ? ThemeMode.dark
          : themeModeString == 'light'
          ? ThemeMode.light
          : ThemeMode.system;

    } catch (e) {
      print('Error initializing: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set date range
  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  // Add transaction
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    await StorageService.saveTransactions(_transactions);
    notifyListeners();
  }

  // Add multiple transactions (for import)
  Future<void> addTransactions(List<Transaction> transactions) async {
    // Auto-categorize new transactions
    for (var transaction in transactions) {
      if (transaction.categoryId == 'uncategorized') {
        transaction.categoryId = _findBestCategory(transaction.description);
      }
    }

    _transactions.addAll(transactions);
    await StorageService.saveTransactions(_transactions);
    notifyListeners();
  }

  // Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      await StorageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
    await StorageService.saveTransactions(_transactions);
    notifyListeners();
  }

  // Update transaction category
  Future<void> updateTransactionCategory(String transactionId, String categoryId) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      _transactions[index].categoryId = categoryId;
      await StorageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  // Add category
  Future<void> addCategory(Category category) async {
    _categories.add(category);
    await StorageService.saveCategories(_categories);
    notifyListeners();
  }

  // Update category
  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      await StorageService.saveCategories(_categories);
      notifyListeners();
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    // Move transactions to uncategorized
    for (var transaction in _transactions) {
      if (transaction.categoryId == categoryId) {
        transaction.categoryId = 'uncategorized';
      }
    }

    _categories.removeWhere((c) => c.id == categoryId);
    await StorageService.saveCategories(_categories);
    await StorageService.saveTransactions(_transactions);
    notifyListeners();
  }

  // Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Find best matching category for a description
  String _findBestCategory(String description) {
    final lowerDesc = description.toLowerCase();

    for (var category in _categories) {
      for (var keyword in category.keywords) {
        if (lowerDesc.contains(keyword.toLowerCase())) {
          return category.id;
        }
      }
    }

    return 'uncategorized';
  }

  // Get transactions by category
  List<Transaction> getTransactionsByCategory(String categoryId) {
    return filteredTransactions.where((t) => t.categoryId == categoryId).toList();
  }

  // Clear all data
  Future<void> clearAllData() async {
    _transactions.clear();
    _categories = Category.getDefaultCategories();
    await StorageService.clearAllData();
    await StorageService.saveCategories(_categories);
    notifyListeners();
  }

  // Settings methods
  Future<void> setCurrency(String code, String symbol) async {
    _currencyCode = code;
    _currencySymbol = symbol;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await StorageService.saveSettings({
      'currencyCode': _currencyCode,
      'currencySymbol': _currencySymbol,
      'themeMode': _themeMode == ThemeMode.dark
          ? 'dark'
          : _themeMode == ThemeMode.light
          ? 'light'
          : 'system',
    });
  }

  // Get monthly statistics
  Map<String, Map<String, double>> getMonthlyStats(int months) {
    final Map<String, Map<String, double>> stats = {};
    final now = DateTime.now();

    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yyyy').format(month);
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      final monthTransactions = _transactions.where((t) =>
      t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1)))
      ).toList();

      double income = 0;
      double expenses = 0;

      for (var t in monthTransactions) {
        if (t.type == TransactionType.income) {
          income += t.amount.abs();
        } else {
          expenses += t.amount.abs();
        }
      }

      stats[monthKey] = {
        'income': income,
        'expenses': expenses,
        'net': income - expenses,
      };
    }

    return stats;
  }

  // Export data as JSON string
  Future<String> exportDataAsJson() async {
    return await StorageService.exportData();
  }

  // Import data from JSON string
  Future<bool> importDataFromJson(String jsonString) async {
    try {
      final success = await StorageService.importData(jsonString);
      if (success) {
        await initialize();
      }
      return success;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
}

// Category Summary model
class CategorySummary {
  final String categoryId;
  final String categoryName;
  final double amount;
  final Color color;
  final IconData icon;

  CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.color,
    required this.icon,
  });
}