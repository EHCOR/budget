// widgets/transaction_details_popup.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../providers/undo_redo_provider.dart';

class TransactionDetailsPopup {
  static void show(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            final category = provider.getCategoryById(transaction.categoryId);

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return _TransactionDetailsContent(
                  transaction: transaction,
                  category: category,
                  provider: provider,
                  scrollController: scrollController,
                );
              },
            );
          },
        );
      },
    );
  }

  static Widget _buildDetailRow(String label, String value) {
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


  static void _confirmDelete(BuildContext context, Transaction transaction, TransactionProvider provider) {
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
            onPressed: () async {
              final undoRedoProvider = Provider.of<UndoRedoProvider>(context, listen: false);
              final command = provider.createDeleteTransactionCommand(transaction.id);
              await undoRedoProvider.executeCommand(command);

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

  static Future<void> _handleUncategorizedSelection(BuildContext context, Transaction transaction, Category category, TransactionProvider provider) async {
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
      await _createTagAndCategorize(context, transaction, category, provider);
    } else {
      // Just update this single transaction
      final undoRedoProvider = Provider.of<UndoRedoProvider>(context, listen: false);
      final command = provider.createUpdateTransactionCategoryCommand(transaction.id, category.id);
      await undoRedoProvider.executeCommand(command);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category updated to ${category.name}')),
        );
      }
    }
  }

  static Future<void> _createTagAndCategorize(BuildContext context, Transaction transaction, Category category, TransactionProvider provider) async {
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

      if (context.mounted) {
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

class _TransactionDetailsContent extends StatefulWidget {
  final Transaction transaction;
  final Category? category;
  final TransactionProvider provider;
  final ScrollController scrollController;

  const _TransactionDetailsContent({
    required this.transaction,
    required this.category,
    required this.provider,
    required this.scrollController,
  });

  @override
  State<_TransactionDetailsContent> createState() => _TransactionDetailsContentState();
}

class _TransactionDetailsContentState extends State<_TransactionDetailsContent> {
  final TextEditingController _searchController = TextEditingController();
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.provider.categories;
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCategories);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = widget.provider.categories.where((category) {
        return category.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  List<Category> _getSortedCategories() {
    final categories = List<Category>.from(_filteredCategories);

    // Find uncategorized category and move it to the top
    final uncategorizedIndex = categories.indexWhere((cat) => cat.id == 'uncategorized');
    if (uncategorizedIndex != -1) {
      final uncategorized = categories.removeAt(uncategorizedIndex);
      categories.insert(0, uncategorized);
    }

    return categories;
  }

  @override
  Widget build(BuildContext context) {
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
            widget.transaction.description,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          TransactionDetailsPopup._buildDetailRow('Date', DateFormat.yMMMMd().format(widget.transaction.date)),
          TransactionDetailsPopup._buildDetailRow('Amount', NumberFormat.currency(symbol: widget.provider.currencySymbol).format(widget.transaction.amount)),
          TransactionDetailsPopup._buildDetailRow('Type', widget.transaction.type == TransactionType.income ? 'Income' : 'Expense'),
          TransactionDetailsPopup._buildDetailRow('Category', widget.category?.name ?? 'Uncategorized'),

          const SizedBox(height: 20),

          // Category selection section
          Text(
            'Change Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),

          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search categories...',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Categories list
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _getSortedCategories().length,
              itemBuilder: (context, index) {
                final category = _getSortedCategories()[index];
                final isSelected = category.id == widget.transaction.categoryId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: isSelected ? 2 : 0,
                  color: isSelected ? category.color.withOpacity(0.1) : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.color.withOpacity(0.2),
                      child: Icon(category.icon, color: category.color, size: 20),
                    ),
                    title: Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                      ? Icon(Icons.check_circle, color: category.color)
                      : null,
                    onTap: () async {
                      if (widget.transaction.categoryId == 'uncategorized') {
                        Navigator.pop(context);
                        await TransactionDetailsPopup._handleUncategorizedSelection(
                          context,
                          widget.transaction,
                          category,
                          widget.provider
                        );
                      } else {
                        final undoRedoProvider = Provider.of<UndoRedoProvider>(context, listen: false);
                        final command = widget.provider.createUpdateTransactionCategoryCommand(widget.transaction.id, category.id);
                        await undoRedoProvider.executeCommand(command);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Category updated to ${category.name}')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Delete button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete Transaction', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                TransactionDetailsPopup._confirmDelete(context, widget.transaction, widget.provider);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}