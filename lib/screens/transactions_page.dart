// screens/transactions_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category_summary.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/nav_bar.dart';
import '../widgets/add_transaction_dialog.dart';

class TransactionsPage extends StatefulWidget {
  final String? initialCategoryId;
  final bool showDrawer;
  
  const TransactionsPage({
    super.key,
    this.initialCategoryId,
    this.showDrawer = true,
  });

  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  TransactionType? _selectedType;
  bool _showOnlyUncategorized = false;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }
  
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
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTransactionDialog(context),
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      drawer: widget.showDrawer ? const NavBar() : null,
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            child: Column(
              children: [
                DateRangeSelector(),
                SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                
                // Active filters display
                if (_selectedCategoryId != null || _selectedType != null || _showOnlyUncategorized)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_showOnlyUncategorized)
                            Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text('Uncategorized Only'),
                                avatar: Icon(
                                  Icons.help_outline,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                deleteIcon: Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _showOnlyUncategorized = false;
                                  });
                                },
                                backgroundColor: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                          if (_selectedCategoryId != null && !_showOnlyUncategorized)
                            Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Consumer<TransactionData>(
                                builder: (context, data, child) {
                                  final category = data.categories.firstWhere(
                                    (c) => c.id == _selectedCategoryId,
                                    orElse: () => Category(
                                      id: 'uncategorized',
                                      name: 'Uncategorized',
                                      color: Colors.grey,
                                      icon: Icons.help_outline,
                                      tags: [],
                                    ),
                                  );
                                  
                                  return Chip(
                                    label: Text('Category: ${category.name}'),
                                    avatar: Icon(
                                      category.icon,
                                      size: 16,
                                      color: category.color,
                                    ),
                                    deleteIcon: Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedCategoryId = null;
                                      });
                                    },
                                    backgroundColor: category.color.withOpacity(0.1),
                                  );
                                },
                              ),
                            ),
                          if (_selectedType != null)
                            Chip(
                              label: Text(
                                'Type: ${_selectedType == TransactionType.income ? 'Income' : 'Expense'}',
                              ),
                              avatar: Icon(
                                _selectedType == TransactionType.income
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 16,
                                color: _selectedType == TransactionType.income
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              deleteIcon: Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedType = null;
                                });
                              },
                              backgroundColor: (_selectedType == TransactionType.income
                                  ? Colors.green
                                  : Colors.red).withOpacity(0.1),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Transactions list
          Expanded(
            child: Consumer<TransactionData>(
              builder: (context, data, child) {
                if (data.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (data.transactions.isEmpty) {
                  return Center(
                    child: Text('No transactions found'),
                  );
                }
                
                // Apply filters and sort
                var transactions = data.filteredTransactions;
                
                // Apply uncategorized filter if selected
                if (_showOnlyUncategorized) {
                  transactions = transactions
                      .where((t) => t.category == 'Uncategorized')
                      .toList();
                }
                // Apply category filter if selected
                else if (_selectedCategoryId != null) {
                  transactions = transactions
                      .where((t) => t.category == _selectedCategoryId)
                      .toList();
                }
                
                // Apply type filter if selected
                if (_selectedType != null) {
                  transactions = transactions
                      .where((t) => t.type == _selectedType)
                      .toList();
                }
                
                // Apply search query if any
                if (_searchQuery.isNotEmpty) {
                  transactions = transactions
                      .where((t) =>
                          t.description.toLowerCase().contains(_searchQuery) ||
                          t.category.toLowerCase().contains(_searchQuery) ||
                          t.amount.toString().contains(_searchQuery) ||
                          DateFormat('yyyy-MM-dd').format(t.date).contains(_searchQuery))
                      .toList();
                }
                
                // Sort by date (newest first)
                transactions.sort((a, b) => b.date.compareTo(a.date));
                
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No transactions match your filters',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedCategoryId = null;
                              _selectedType = null;
                              _showOnlyUncategorized = false;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          icon: Icon(Icons.filter_alt_off),
                          label: Text('Clear filters'),
                        ),
                      ],
                    ),
                  );
                }
                
                // Group transactions by date
                final groupedTransactions = <DateTime, List<Transaction>>{};
                for (var transaction in transactions) {
                  final dateKey = DateTime(
                    transaction.date.year,
                    transaction.date.month,
                    transaction.date.day,
                  );
                  
                  if (!groupedTransactions.containsKey(dateKey)) {
                    groupedTransactions[dateKey] = [];
                  }
                  
                  groupedTransactions[dateKey]!.add(transaction);
                }
                
                // Sort dates (newest first)
                final dates = groupedTransactions.keys.toList()
                  ..sort((a, b) => b.compareTo(a));
                
                return ListView.builder(
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final dayTransactions = groupedTransactions[date]!;
                    
                    // Calculate total for the day
                    final dayTotal = dayTransactions.fold(
                      0.0,
                      (sum, t) => sum + t.amount,
                    );
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Container(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat.yMMMd().format(date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(symbol: data.currencySymbol).format(dayTotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: dayTotal >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Day's transactions
                        ...dayTransactions.map((transaction) => _buildTransactionItem(
                          context,
                          transaction,
                          data,
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionItem(
    BuildContext context,
    Transaction transaction,
    TransactionData data,
  ) {
    final category = data.categories.firstWhere(
      (c) => c.id == transaction.category,
      orElse: () => Category(
        id: 'uncategorized',
        name: 'Uncategorized',
        color: Colors.grey,
        icon: Icons.help_outline,
        tags: [],
      ),
    );
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: InkWell(
        onTap: () => _showTransactionDetails(context, transaction, category),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: category.color.withOpacity(0.2),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: category.color,
                          ),
                        ),
                        Spacer(),
                        if (transaction.balance != 0)
                          Text(
                            'Balance: ${NumberFormat.currency(symbol: data.currencySymbol).format(transaction.balance)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Text(
                NumberFormat.currency(symbol: data.currencySymbol).format(transaction.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.amount < 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showTransactionDetails(
    BuildContext context,
    Transaction transaction,
    Category category,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<TransactionData>(
              builder: (context, data, child) {
                return Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      transaction.description,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    NumberFormat.currency(symbol: data.currencySymbol).format(transaction.amount),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: transaction.amount < 0 ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildDetailRow(
                                'Date',
                                DateFormat.yMMMMd().format(transaction.date),
                                Icons.calendar_today,
                              ),
                              _buildDetailRow(
                                'Category',
                                category.name,
                                category.icon,
                                color: category.color,
                                onTap: () => _showCategorySelectionDialog(context, transaction),
                              ),
                              _buildDetailRow(
                                'Type',
                                transaction.type == TransactionType.income
                                    ? 'Income'
                                    : 'Expense',
                                transaction.type == TransactionType.income
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: transaction.type == TransactionType.income
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              if (transaction.balance != 0)
                                _buildDetailRow(
                                  'Balance',
                                  NumberFormat.currency(symbol: data.currencySymbol).format(transaction.balance),
                                  Icons.account_balance_wallet,
                                ),
                              _buildDetailRow(
                                'Transaction ID',
                                transaction.id,
                                Icons.tag,
                                isSubtle: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Delete', style: TextStyle(color: Colors.red)),
                              onPressed: () => _showDeleteTransactionDialog(context, transaction),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
        );
      },
    );
  }
  
  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddTransactionDialog();
      },
    );
  }
  
  void _showDeleteTransactionDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
            'Are you sure you want to delete "${transaction.description}"?\n\n'
            'This action cannot be undone.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final provider = Provider.of<TransactionData>(
                  context, 
                  listen: false
                );
                
                provider.deleteTransaction(transaction.id);
                
                // Close the detail bottom sheet and dialog
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context); // Close the bottom sheet
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted successfully'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool isSubtle = false,
    VoidCallback? onTap,
  }) {
    final row = Row(
      children: [
        Icon(
          icon,
          color: color ?? Colors.grey[700],
          size: 20,
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isSubtle ? 12 : 16,
                color: isSubtle ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
        if (onTap != null) ...[
          Spacer(),
          Icon(
            Icons.edit,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ],
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: row,
        ),
      );
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: row,
    );
  }
  
  void _showCategorySelectionDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<TransactionData>(
          builder: (context, data, child) {
            return AlertDialog(
              title: Text('Select Category'),
              content: Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.categories.length,
                  itemBuilder: (context, index) {
                    final category = data.categories[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color.withOpacity(0.2),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 20,
                        ),
                      ),
                      title: Text(category.name),
                      trailing: transaction.category == category.id
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () async {
                        Navigator.pop(context);
                        await data.updateTransactionCategory(
                          transaction.id,
                          category.id,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Transaction updated to category: ${category.name}',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer<TransactionData>(
              builder: (context, data, child) {
                return Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Filter Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Transaction Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FilterChip(
                              label: Text('Income'),
                              selected: _selectedType == TransactionType.income,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedType = selected
                                      ? TransactionType.income
                                      : null;
                                });
                                setState(() {});
                              },
                              avatar: Icon(
                                Icons.arrow_upward,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: FilterChip(
                              label: Text('Expense'),
                              selected: _selectedType == TransactionType.expense,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedType = selected
                                      ? TransactionType.expense
                                      : null;
                                });
                                setState(() {});
                              },
                              avatar: Icon(
                                Icons.arrow_downward,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Add Uncategorized filter
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: Text('Show only uncategorized'),
                              value: _showOnlyUncategorized,
                              onChanged: (value) {
                                setModalState(() {
                                  _showOnlyUncategorized = value ?? false;
                                  // Clear category selection if uncategorized filter is enabled
                                  if (_showOnlyUncategorized) {
                                    _selectedCategoryId = null;
                                  }
                                });
                                setState(() {});
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      if (!_showOnlyUncategorized) ...[
                        SizedBox(height: 16),
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...data.categories.map((category) {
                              return FilterChip(
                                label: Text(category.name),
                                selected: _selectedCategoryId == category.id,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedCategoryId = selected
                                        ? category.id
                                        : null;
                                  });
                                  setState(() {});
                                },
                                avatar: Icon(
                                  category.icon,
                                  size: 16,
                                  color: category.color,
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                _selectedCategoryId = null;
                                _selectedType = null;
                                _showOnlyUncategorized = false;
                              });
                              setState(() {});
                            },
                            icon: Icon(Icons.clear_all),
                            label: Text('Clear Filters'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.check),
                            label: Text('Apply'),
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
}