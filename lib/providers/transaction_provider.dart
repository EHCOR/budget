// providers/transaction_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/command.dart';
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

  // Add multiple transactions (for import) with duplicate detection
  Future<Map<String, int>> addTransactions(List<Transaction> transactions) async {
    final duplicateResults = _detectDuplicates(transactions);
    final uniqueTransactions = duplicateResults['unique'] as List<Transaction>;
    final duplicateCount = duplicateResults['duplicates'] as int;

    // Auto-categorize new transactions
    for (var transaction in uniqueTransactions) {
      if (transaction.categoryId == 'uncategorized') {
        transaction.categoryId = _findBestCategory(transaction.description);
      }
    }

    _transactions.addAll(uniqueTransactions);
    await StorageService.saveTransactions(_transactions);
    notifyListeners();

    return {
      'imported': uniqueTransactions.length,
      'duplicates': duplicateCount,
      'total': transactions.length,
    };
  }

  // Detect duplicate transactions
  Map<String, dynamic> _detectDuplicates(List<Transaction> newTransactions) {
    final List<Transaction> uniqueTransactions = [];
    int duplicateCount = 0;

    for (var newTransaction in newTransactions) {
      if (!_isDuplicate(newTransaction)) {
        uniqueTransactions.add(newTransaction);
      } else {
        duplicateCount++;
      }
    }

    return {
      'unique': uniqueTransactions,
      'duplicates': duplicateCount,
    };
  }

  // Check if a transaction is a duplicate
  bool _isDuplicate(Transaction newTransaction) {
    for (var existingTransaction in _transactions) {
      if (_transactionsMatch(existingTransaction, newTransaction)) {
        return true;
      }
    }
    return false;
  }

  // Check if two transactions match (considering them duplicates)
  bool _transactionsMatch(Transaction existing, Transaction candidate) {
    return existing.date.isAtSameMomentAs(candidate.date) &&
           existing.amount == candidate.amount &&
           existing.description == candidate.description;
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
      if (_matchesKeywords(lowerDesc, category.keywords)) {
        return category.id;
      }
    }

    return 'uncategorized';
  }

  // Helper method to check if a description matches any of the given keywords
  bool _matchesKeywords(String lowerDescription, List<String> keywords) {
    for (var keyword in keywords) {
      if (lowerDescription.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  // Count transactions that would match a set of keywords
  int countTransactionsByKeywords(List<String> keywords) {
    if (keywords.isEmpty) return 0;

    int count = 0;
    for (var transaction in _transactions) {
      // Only consider uncategorized transactions
      if (transaction.categoryId == 'uncategorized') {
        final lowerDesc = transaction.description.toLowerCase();
        if (_matchesKeywords(lowerDesc, keywords)) {
          count++;
        }
      }
    }
    return count;
  }

  // Recategorize transactions based on keywords
  Future<int> recategorizeTransactionsByKeywords(String categoryId, List<String> keywords) async {
    if (keywords.isEmpty) return 0;

    int recategorizedCount = 0;

    for (var transaction in _transactions) {
      // Only recategorize uncategorized transactions
      if (transaction.categoryId == 'uncategorized') {
        final lowerDesc = transaction.description.toLowerCase();
        if (_matchesKeywords(lowerDesc, keywords)) {
          transaction.categoryId = categoryId;
          recategorizedCount++;
        }
      }
    }

    if (recategorizedCount > 0) {
      await StorageService.saveTransactions(_transactions);
      notifyListeners();
    }

    return recategorizedCount;
  }

  // Calculate the number of transactions that will be changed by updating a category
  Map<String, int> calculateCategoryChanges(Category category, List<String> newKeywords) {
    int added = 0;
    int removed = 0;

    // Find transactions that will be removed from this category
    final currentTransactions = getTransactionsByCategory(category.id);
    for (var transaction in currentTransactions) {
      final lowerDesc = transaction.description.toLowerCase();
      if (!_matchesKeywords(lowerDesc, newKeywords)) {
        removed++;
      }
    }

    // Find transactions that will be added to this category from any other category
    final otherTransactions = _transactions.where((t) => t.categoryId != category.id);
    for (var transaction in otherTransactions) {
      final lowerDesc = transaction.description.toLowerCase();
      if (_matchesKeywords(lowerDesc, newKeywords)) {
        added++;
      }
    }

    return {'added': added, 'removed': removed};
  }

  // Update category and recategorize transactions based on new keywords
  Future<Map<String, int>> updateCategoryAndRecategorize(Category category, List<String> newKeywords) async {
    int added = 0;
    int removed = 0;

    // Remove transactions that no longer match the new keywords
    final currentTransactions = _transactions.where((t) => t.categoryId == category.id).toList();
    for (var transaction in currentTransactions) {
      final lowerDesc = transaction.description.toLowerCase();
      if (!_matchesKeywords(lowerDesc, newKeywords)) {
        transaction.categoryId = 'uncategorized';
        removed++;
      }
    }

    // Add transactions that now match the new keywords (from any other category including uncategorized)
    final otherTransactions = _transactions.where((t) => t.categoryId != category.id).toList();
    for (var transaction in otherTransactions) {
      final lowerDesc = transaction.description.toLowerCase();
      if (_matchesKeywords(lowerDesc, newKeywords)) {
        transaction.categoryId = category.id;
        added++;
      }
    }

    if (added > 0 || removed > 0) {
      await StorageService.saveTransactions(_transactions);
      notifyListeners();
    }

    return {'added': added, 'removed': removed};
  }

  // Get transactions by category
  List<Transaction> getTransactionsByCategory(String categoryId) {
    return filteredTransactions.where((t) => t.categoryId == categoryId).toList();
  }

  // Recalculate all transactions for the last 3 months
  Future<Map<String, int>> recalculateAllTransactions({int months = 3}) async {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - months, now.day);

    int recategorized = 0;
    int alreadyCategorized = 0;

    // Filter transactions to last 3 months
    final recentTransactions = _transactions.where((t) =>
      t.date.isAfter(threeMonthsAgo)
    ).toList();

    for (var transaction in recentTransactions) {
      // Only recalculate uncategorized transactions or find better matches
      if (transaction.categoryId == 'uncategorized') {
        final bestCategory = _findBestCategory(transaction.description);
        if (bestCategory != 'uncategorized') {
          transaction.categoryId = bestCategory;
          recategorized++;
        }
      } else {
        alreadyCategorized++;
      }
    }

    if (recategorized > 0) {
      await StorageService.saveTransactions(_transactions);
      notifyListeners();
    }

    return {
      'recategorized': recategorized,
      'alreadyCategorized': alreadyCategorized,
      'total': recentTransactions.length,
    };
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

  // Get monthly category data for trends
  Map<String, Map<String, Map<String, double>>> getMonthlyCategoryData() {
    final Map<String, Map<String, Map<String, double>>> result = {};
    final transactionsInRange = filteredTransactions;

    if (transactionsInRange.isEmpty) {
      return result;
    }

    // Determine the range of months from the filtered transactions
    final firstDate = transactionsInRange.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final lastDate = transactionsInRange.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);

    DateTime currentMonth = DateTime(firstDate.year, firstDate.month, 1);
    while (currentMonth.isBefore(lastDate) || currentMonth.isAtSameMomentAs(lastDate)) {
      final monthKey = DateFormat('MMM yyyy').format(currentMonth);
      result[monthKey] = {'income': {}, 'expense': {}};
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }

    // Populate the data
    for (var transaction in transactionsInRange) {
      final monthKey = DateFormat('MMM yyyy').format(transaction.date);
      final category = getCategoryById(transaction.categoryId);
      final categoryName = category?.name ?? 'Unknown';
      final type = transaction.type == TransactionType.income ? 'income' : 'expense';
      final amount = transaction.amount.abs();

      if (result.containsKey(monthKey)) {
        result[monthKey]![type]![categoryName] =
            (result[monthKey]![type]![categoryName] ?? 0) + amount;
      }
    }

    return result;
  }

  // Get category colors map for charts
  Map<String, Color> getCategoryColorsMap() {
    final Map<String, Color> colors = {};
    for (var category in _categories) {
      colors[category.name] = category.color;
    }
    colors['Unknown'] = Colors.grey;
    return colors;
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

  // Command-based transaction methods for undo/redo support

  // Internal method to add transaction without command wrapper
  Future<void> _addTransactionInternal(Map<String, dynamic> transactionData) async {
    final transaction = Transaction.fromJson(transactionData);
    _transactions.add(transaction);
    await StorageService.saveTransactions(_transactions);
    notifyListeners();
  }

  // Internal method to delete transaction without command wrapper
  Future<void> _deleteTransactionInternal(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
    await StorageService.saveTransactions(_transactions);
    notifyListeners();
  }

  // Internal method to update transaction without command wrapper
  Future<void> _updateTransactionInternal(Map<String, dynamic> transactionData) async {
    final transaction = Transaction.fromJson(transactionData);
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      await StorageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  // Internal method to update transaction category without command wrapper
  Future<void> _updateTransactionCategoryInternal(String transactionId, String categoryId) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      _transactions[index].categoryId = categoryId;
      await StorageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  // Create commands for undo/redo operations
  AddTransactionCommand createAddTransactionCommand(Transaction transaction) {
    return AddTransactionCommand(
      transactionId: transaction.id,
      transactionData: transaction.toJson(),
      deleteTransaction: _deleteTransactionInternal,
      addTransaction: _addTransactionInternal,
    );
  }

  DeleteTransactionCommand createDeleteTransactionCommand(String transactionId) {
    final transaction = _transactions.firstWhere((t) => t.id == transactionId);
    return DeleteTransactionCommand(
      transactionId: transactionId,
      transactionData: transaction.toJson(),
      deleteTransaction: _deleteTransactionInternal,
      addTransaction: _addTransactionInternal,
    );
  }

  UpdateTransactionCommand createUpdateTransactionCommand(Transaction oldTransaction, Transaction newTransaction) {
    return UpdateTransactionCommand(
      transactionId: newTransaction.id,
      oldData: oldTransaction.toJson(),
      newData: newTransaction.toJson(),
      updateTransaction: _updateTransactionInternal,
    );
  }

  UpdateTransactionCategoryCommand createUpdateTransactionCategoryCommand(String transactionId, String newCategoryId) {
    final transaction = _transactions.firstWhere((t) => t.id == transactionId);
    return UpdateTransactionCategoryCommand(
      transactionId: transactionId,
      oldCategoryId: transaction.categoryId,
      newCategoryId: newCategoryId,
      updateTransactionCategory: _updateTransactionCategoryInternal,
    );
  }

  // Get transaction by ID
  Transaction? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
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