// screens/transactions_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/transaction_details_popup.dart';
import '../widgets/undo_redo_controls.dart';
import 'settings_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _searchQuery = '';
  String? _selectedCategoryId;
  TransactionType? _selectedType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          const UndoRedoControls(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search and filters
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Date selector
                    const DateRangeSelector(),
                    const SizedBox(height: 12),

                    // Search bar with action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search transactions...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.auto_fix_high),
                          onPressed: () => _showRecalculateDialog(context),
                          tooltip: 'Recalculate Categories',
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFilterSheet,
                          tooltip: 'Filter',
                        ),
                      ],
                    ),

                    // Active filters
                    if (_selectedCategoryId != null || _selectedType != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (_selectedCategoryId != null)
                              Chip(
                                label: Text(provider.getCategoryById(_selectedCategoryId!)?.name ?? ''),
                                onDeleted: () => setState(() => _selectedCategoryId = null),
                              ),
                            if (_selectedType != null)
                              Chip(
                                label: Text(_selectedType == TransactionType.income ? 'Income' : 'Expenses'),
                                onDeleted: () => setState(() => _selectedType = null),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Transactions list
              Expanded(
                child: _buildTransactionsList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList(TransactionProvider provider) {
    // Apply filters
    var transactions = provider.filteredTransactions;

    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((t) =>
      t.description.toLowerCase().contains(_searchQuery) ||
          provider.getCategoryById(t.categoryId)?.name.toLowerCase().contains(_searchQuery) == true
      ).toList();
    }

    if (_selectedCategoryId != null) {
      transactions = transactions.where((t) => t.categoryId == _selectedCategoryId).toList();
    }

    if (_selectedType != null) {
      transactions = transactions.where((t) => t.type == _selectedType).toList();
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No transactions found'),
            if (_searchQuery.isNotEmpty || _selectedCategoryId != null || _selectedType != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedCategoryId = null;
                    _selectedType = null;
                  });
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <DateTime, List<Transaction>>{};
    for (var transaction in transactions) {
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      grouped[date] ??= [];
      grouped[date]!.add(transaction);
    }

    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final dayTransactions = grouped[date]!;
        final dayTotal = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat.yMMMd().format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    NumberFormat.currency(symbol: provider.currencySymbol).format(dayTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: dayTotal >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            // Transactions for this day
            ...dayTransactions.map((transaction) => _buildTransactionTile(transaction, provider)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(Transaction transaction, TransactionProvider provider) {
    final category = provider.getCategoryById(transaction.categoryId);

    return Dismissible(
      key: Key(transaction.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (category?.color ?? Colors.grey).withValues(alpha: 0.2),
          child: Icon(
            category?.icon ?? Icons.help_outline,
            color: category?.color ?? Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(category?.name ?? 'Uncategorized'),
        trailing: Text(
          NumberFormat.currency(symbol: provider.currencySymbol).format(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
          ),
        ),
        onTap: () => TransactionDetailsPopup.show(context, transaction),
      ),
    );
  }


  void _showRecalculateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recalculate Categories'),
        content: const Text(
          'This will automatically categorize uncategorized transactions from the last 3 months based on your current category keywords.\n\n'
          'Do you want to proceed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performRecalculation(context);
            },
            child: const Text('Recalculate'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRecalculation(BuildContext context) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Recalculating categories...'),
          ],
        ),
      ),
    );

    try {
      final results = await provider.recalculateAllTransactions();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recalculation complete: ${results['recategorized']} transactions recategorized, '
              '${results['alreadyCategorized']} already categorized '
              '(${results['total']} total transactions processed)'
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during recalculation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter Transactions',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // Type filter card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Transaction Type',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFilterOption(
                                        context,
                                        'Income',
                                        Icons.trending_up,
                                        Colors.green,
                                        _selectedType == TransactionType.income,
                                        () {
                                          setModalState(() {
                                            _selectedType = _selectedType == TransactionType.income
                                                ? null
                                                : TransactionType.income;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildFilterOption(
                                        context,
                                        'Expenses',
                                        Icons.trending_down,
                                        Colors.red,
                                        _selectedType == TransactionType.expense,
                                        () {
                                          setModalState(() {
                                            _selectedType = _selectedType == TransactionType.expense
                                                ? null
                                                : TransactionType.expense;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Category filter card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: provider.categories.map((category) {
                                        return _buildCategoryFilterOption(
                                          context,
                                          category,
                                          _selectedCategoryId == category.id,
                                          () {
                                            setModalState(() {
                                              _selectedCategoryId = _selectedCategoryId == category.id
                                                  ? null
                                                  : category.id;
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedType = null;
                                    _selectedCategoryId = null;
                                  });
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Clear All'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Apply Filters'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.15)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterOption(
    BuildContext context,
    Category category,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: isSelected
          ? category.color.withValues(alpha: 0.15)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? category.color
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                color: isSelected ? category.color : Theme.of(context).colorScheme.onSurface,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: TextStyle(
                  color: isSelected ? category.color : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}