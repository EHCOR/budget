// widgets/transaction_details_popup.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/transaction_provider.dart';

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
                                _showCategoryPicker(context, transaction, provider);
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
                                _confirmDelete(context, transaction, provider);
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

  static void _showCategoryPicker(BuildContext context, Transaction transaction, TransactionProvider provider) {
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
                    await _handleUncategorizedSelection(context, transaction, category, provider);
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
      await provider.updateTransactionCategory(transaction.id, category.id);
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