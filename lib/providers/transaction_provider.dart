// providers/transaction_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category_summary.dart';
import '../utils/category_matcher.dart';
import '../utils/storage_service.dart';

class TransactionData extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<CategorySummary> _categorySummaries = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final CategoryMatcher _categoryMatcher = CategoryMatcher();
  bool _isLoading = false;
  String _currencySymbol = '\$';
  String _currencyCode = 'USD';
  ThemeMode _themeMode = ThemeMode.light;

  // Getters
  List<Transaction> get transactions => _transactions;
  List<CategorySummary> get categorySummaries => _categorySummaries;
  List<CategorySummary> get incomeSummaries =>
      _categorySummaries.where((s) => s.isIncome).toList();
  List<CategorySummary> get expenseSummaries =>
      _categorySummaries.where((s) => !s.isIncome).toList();
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;
  ThemeMode get themeMode => _themeMode;

  // Get filtered transactions based on current date range
  List<Transaction> get filteredTransactions {
    return _transactions
        .where(
          (t) =>
              t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              t.date.isBefore(_endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  // Get uncategorized transactions
  List<Transaction> get uncategorizedTransactions {
    return filteredTransactions
        .where((t) => t.category == 'Uncategorized')
        .toList();
  }

  // Get transactions by category ID
  List<Transaction> getTransactionsByCategory(String categoryId) {
    return filteredTransactions.where((t) => t.category == categoryId).toList();
  }

  // Get total income for current period
  double get totalIncome {
    return filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Get total expenses for current period
  double get totalExpenses {
    return filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount.abs());
  }

  // Get net cash flow for current period
  double get netCashFlow {
    return totalIncome - totalExpenses;
  }

  // Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Initialize categories from XML file
      await _categoryMatcher.initializeCategories();

      // Load transactions from storage
      final loadedTransactions = await StorageService.loadTransactions();

      if (loadedTransactions.isNotEmpty) {
        _transactions = loadedTransactions;
        _updateCategorySummaries();
      }

      // Load settings
      await _loadSettings();
    } catch (e) {
      debugPrint('Error initializing transaction provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load settings
  Future<void> _loadSettings() async {
    try {
      final settings = await StorageService.loadSettings();
      if (settings != null) {
        // Load currency settings
        if (settings.containsKey('currencyCode')) {
          _currencyCode = settings['currencyCode'];
          _currencySymbol = settings['currencySymbol'] ?? '\$';
        }

        // Load theme settings
        if (settings.containsKey('themeMode')) {
          final themeModeString = settings['themeMode'];
          if (themeModeString == 'dark') {
            _themeMode = ThemeMode.dark;
          } else if (themeModeString == 'light') {
            _themeMode = ThemeMode.light;
          } else {
            _themeMode = ThemeMode.system;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
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
    _updateCategorySummaries();
    notifyListeners();
  }

  // Set currency
  Future<void> setCurrency(String code, String symbol) async {
    _currencyCode = code;
    _currencySymbol = symbol;

    // Get current settings and update
    final settings = await StorageService.loadSettings() ?? {};
    settings['currencyCode'] = code;
    settings['currencySymbol'] = symbol;

    // Save settings
    await StorageService.saveSettings(settings);

    notifyListeners();
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    // Get current settings and update
    final settings = await StorageService.loadSettings() ?? {};
    settings['themeMode'] =
        mode == ThemeMode.dark
            ? 'dark'
            : (mode == ThemeMode.light ? 'light' : 'system');

    // Save settings
    await StorageService.saveSettings(settings);

    notifyListeners();
  }

  // Add transactions
  Future<void> addTransactions(List<Transaction> newTransactions) async {
    _setLoading(true);
    try {
      // Check for duplicates based on date, amount, and description
      final uniqueTransactions =
          newTransactions.where((newTx) {
            return !_transactions.any(
              (existingTx) =>
                  existingTx.date == newTx.date &&
                  existingTx.amount == newTx.amount &&
                  existingTx.description == newTx.description,
            );
          }).toList();

      if (uniqueTransactions.isEmpty) {
        _setLoading(false);
        return;
      }

      _transactions.addAll(uniqueTransactions);
      _assignCategories(uniqueTransactions);
      _updateCategorySummaries();
      await StorageService.saveTransactions(_transactions);
    } catch (e) {
      debugPrint('Error adding transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add single transaction (for manual entry)
  Future<void> addTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      _transactions.add(transaction);
      _assignCategories([transaction]);
      _updateCategorySummaries();
      await StorageService.saveTransactions(_transactions);
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    _setLoading(true);
    try {
      _transactions.removeWhere((t) => t.id == transactionId);
      _updateCategorySummaries();
      await StorageService.saveTransactions(_transactions);
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Clear all transactions
  Future<void> clearTransactions() async {
    _setLoading(true);
    try {
      _transactions.clear();
      _categorySummaries.clear();
      await StorageService.deleteAllTransactions();
    } catch (e) {
      debugPrint('Error clearing transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Backup data
  Future<String> backupData() async {
    _setLoading(true);
    try {
      return await StorageService.backupData();
    } finally {
      _setLoading(false);
    }
  }

  // Restore from backup
  Future<void> restoreFromBackup(String backupPath) async {
    _setLoading(true);
    try {
      await StorageService.restoreFromBackup(backupPath);
      _transactions = await StorageService.loadTransactions();
      _updateCategorySummaries();
    } catch (e) {
      debugPrint('Error restoring from backup: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Assign categories to transactions
  void _assignCategories(List<Transaction> transactionsToProcess) {
    for (var transaction in transactionsToProcess) {
      if (transaction.category != 'Uncategorized') continue;

      // Use the CategoryMatcher to find the appropriate category
      String categoryId = _categoryMatcher.matchCategory(
        transaction.description,
      );
      transaction.category = categoryId;
    }
  }

  // Update category summaries
  void _updateCategorySummaries() {
    // Create maps to hold totals by category
    Map<String, double> incomeByCategory = {};
    Map<String, double> expensesByCategory = {};

    // Filter transactions by date
    for (var transaction in filteredTransactions) {
      final categoryId = transaction.category;
      final amount = transaction.amount.abs();

      // Sort into income or expense
      if (transaction.type == TransactionType.income) {
        incomeByCategory[categoryId] =
            (incomeByCategory[categoryId] ?? 0) + amount;
      } else {
        expensesByCategory[categoryId] =
            (expensesByCategory[categoryId] ?? 0) + amount;
      }
    }

    // Convert to list of CategorySummary objects
    List<CategorySummary> summaries = [];

    // Process income categories
    for (var entry in incomeByCategory.entries) {
      final category = _categoryMatcher.getCategoryById(entry.key);
      if (category != null) {
        summaries.add(
          CategorySummary(
            categoryId: entry.key,
            category: category.name,
            totalAmount: entry.value,
            color: category.color,
            icon: category.icon,
            isIncome: true,
          ),
        );
      }
    }

    // Process expense categories
    for (var entry in expensesByCategory.entries) {
      final category = _categoryMatcher.getCategoryById(entry.key);
      if (category != null) {
        summaries.add(
          CategorySummary(
            categoryId: entry.key,
            category: category.name,
            totalAmount: entry.value,
            color: category.color,
            icon: category.icon,
            isIncome: false,
          ),
        );
      }
    }

    // Sort categories by amount (descending)
    summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    _categorySummaries = summaries;
  }

  // Update a transaction's category
  Future<void> updateTransactionCategory(
    String transactionId,
    String newCategoryId,
  ) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) return;

    _transactions[index].category = newCategoryId;
    _updateCategorySummaries();
    await StorageService.saveTransactions(_transactions);
    notifyListeners();
  }

  // Add a new category
  Future<void> addCategory(Category category) async {
    await _categoryMatcher.addCategory(category);
    _updateCategorySummaries();
    notifyListeners();
  }

  // Update a category
  Future<void> updateCategory(Category category) async {
    await _categoryMatcher.updateCategory(category);
    _updateCategorySummaries();
    notifyListeners();
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _categoryMatcher.deleteCategory(categoryId);

    // Reassign transactions with this category to "Uncategorized"
    for (var transaction in _transactions.where(
      (t) => t.category == categoryId,
    )) {
      transaction.category = 'Uncategorized';
    }

    await StorageService.saveTransactions(_transactions);
    _updateCategorySummaries();
    notifyListeners();
  }

  // Get a list of all categories
  List<Category> get categories => _categoryMatcher.categories;

  // Get spending trends by month/category
  Map<String, Map<String, double>> getMonthlySpendingTrends(int monthsCount) {
    final Map<String, Map<String, double>> trends = {};
    final now = DateTime.now();

    for (int i = 0; i < monthsCount; i++) {
      final month = now.subtract(Duration(days: 30 * i));
      final monthLabel = DateFormat('MMM yyyy').format(month);
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      final monthlyTransactions = _transactions.where(
        (t) =>
            t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endOfMonth.add(const Duration(days: 1))) &&
            t.type == TransactionType.expense,
      );

      final monthlyCategoryTotals = <String, double>{};

      for (var t in monthlyTransactions) {
        final category = _categoryMatcher.getCategoryById(t.category);
        if (category != null) {
          final categoryName = category.name;
          monthlyCategoryTotals[categoryName] =
              (monthlyCategoryTotals[categoryName] ?? 0) + t.amount.abs();
        }
      }

      trends[monthLabel] = monthlyCategoryTotals;
    }

    return trends;
  }

  // Get income vs. expenses by month
  Map<String, Map<String, double>> getMonthlyBalances(int monthsCount) {
    final Map<String, Map<String, double>> balances = {};
    final now = DateTime.now();

    for (int i = 0; i < monthsCount; i++) {
      final month = now.subtract(Duration(days: 30 * i));
      final monthLabel = DateFormat('MMM yyyy').format(month);
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      final monthlyTransactions = _transactions.where(
        (t) =>
            t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endOfMonth.add(const Duration(days: 1))),
      );

      double income = 0;
      double expenses = 0;

      for (var t in monthlyTransactions) {
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else if (t.type == TransactionType.expense) {
          expenses += t.amount.abs();
        }
      }

      balances[monthLabel] = {
        'Income': income,
        'Expenses': expenses,
        'Net': income - expenses,
      };
    }

    return balances;
  }
}
