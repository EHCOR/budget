// screens/transactions_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/date_range_selector.dart';

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
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () => _showRecalculateDialog(context),
            tooltip: 'Recalculate Categories',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
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

                    // Search bar
                    TextField(
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
          backgroundColor: (category?.color ?? Colors.grey).withOpacity(0.2),
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
        onTap: () => _showTransactionDetails(transaction, provider),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final category = provider.getCategoryById(transaction.categoryId);

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Transaction details
                  Text(
                    transaction.description,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow('Date', DateFormat.yMMMMd().format(transaction.date)),
                  _buildDetailRow('Amount', NumberFormat.currency(symbol: provider.currencySymbol).format(transaction.amount)),
                  _buildDetailRow('Type', transaction.type == TransactionType.income ? 'Income' : 'Expense'),
                  _buildDetailRow('Category', category?.name ?? 'Uncategorized'),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.category),
                          label: const Text('Change Category'),
                          onPressed: () {
                            Navigator.pop(context);
                            _showCategoryPicker(transaction, provider);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDelete(transaction, provider);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCategoryPicker(Transaction transaction, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              final isSelected = category.id == transaction.categoryId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: category.color.withOpacity(0.2),
                  child: Icon(category.icon, color: category.color, size: 20),
                ),
                title: Text(category.name),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  // Check if this transaction is currently uncategorized
                  if (transaction.categoryId == 'uncategorized') {
                    Navigator.pop(context);
                    await _handleUncategorizedSelection(transaction, category, provider);
                  } else {
                    provider.updateTransactionCategory(transaction.id, category.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Category updated to ${category.name}')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Transaction transaction, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTransaction(transaction.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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
      builder: (context) {
        return Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
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

                      // Type filter
                      const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilterChip(
                              label: const Text('Income'),
                              selected: _selectedType == TransactionType.income,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedType = selected ? TransactionType.income : null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilterChip(
                              label: const Text('Expenses'),
                              selected: _selectedType == TransactionType.expense,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedType = selected ? TransactionType.expense : null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Category filter
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.categories.map((category) {
                          return FilterChip(
                            label: Text(category.name),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedCategoryId = selected ? category.id : null;
                              });
                            },
                          );
                        }).toList(),
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
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {});
                                Navigator.pop(context);
                              },
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleUncategorizedSelection(Transaction transaction, Category category, TransactionProvider provider) async {
    // Ask if user wants to create a new tag for this transaction
    final bool? createTag = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Smart Tag?'),
        content: Text(
          'Would you like to create a smart tag to automatically categorize similar transactions to "${category.name}"?\n\n'
          'This will help categorize future transactions with similar descriptions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, just this transaction'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, create smart tag'),
          ),
        ],
      ),
    );

    if (createTag == true) {
      await _createTagAndCategorize(transaction, category, provider);
    } else {
      // Just update this single transaction
      await provider.updateTransactionCategory(transaction.id, category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category updated to ${category.name}')),
        );
      }
    }
  }

  Future<void> _createTagAndCategorize(Transaction transaction, Category category, TransactionProvider provider) async {
    // Show dialog to get tag input
    final String? tag = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Create Smart Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction: ${transaction.description}'),
              const SizedBox(height: 16),
              const Text('Enter a keyword that will help identify similar transactions:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Tag/Keyword',
                  hintText: 'e.g., "starbucks", "gas station", "pharmacy"',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty) {
                  Navigator.of(context).pop(tag);
                }
              },
              child: const Text('Create Tag'),
            ),
          ],
        );
      },
    );

    if (tag != null && tag.isNotEmpty) {
      // Add the tag to the category and recategorize transactions
      final updatedKeywords = [...category.keywords, tag.toLowerCase()];
      final updatedCategory = category.copyWith(keywords: updatedKeywords);

      await provider.updateCategory(updatedCategory);

      // Recategorize all transactions with the new keywords
      final results = await provider.updateCategoryAndRecategorize(updatedCategory, updatedKeywords);

      final added = results['added'] ?? 0;
      final message = added > 1
          ? 'Smart tag "$tag" created! Categorized $added transactions to ${category.name}'
          : 'Smart tag "$tag" created! Transaction categorized to ${category.name}';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}