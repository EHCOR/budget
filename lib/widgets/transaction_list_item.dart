// widgets/transaction_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category_summary.dart';
import '../providers/transaction_provider.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionData>(context);
    final categoryColor =
        provider.categorySummaries
            .firstWhere(
              (summary) => summary.categoryId == transaction.category,
              orElse:
                  () => CategorySummary(
                    categoryId: transaction.category,
                    category: transaction.category,
                    totalAmount: 0,
                    color: Colors.grey,
                    icon: Icons.help_outline,
                    isIncome: transaction.type == TransactionType.income,
                  ),
            )
            .color;

    // Get the appropriate category name to display
    final categoryName =
        provider.categories
            .firstWhere(
              (c) => c.id == transaction.category,
              orElse:
                  () => Category(
                    id: transaction.category,
                    name: transaction.category,
                    color: Colors.grey,
                    icon: Icons.help_outline,
                    tags: [],
                  ),
            )
            .name;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor,
          child: const Icon(Icons.category, color: Colors.white),
        ),
        title: Text(transaction.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM d, yyyy').format(transaction.date)),
            GestureDetector(
              onTap: () {
                _showCategoryEditor(context, transaction);
              },
              child: Row(
                children: [
                  const Icon(Icons.label, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Text(
          '\$${transaction.amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: transaction.amount < 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showCategoryEditor(BuildContext context, Transaction transaction) {
    final provider = Provider.of<TransactionData>(context, listen: false);
    final categories = provider.categories;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.color,
                    child: Icon(category.icon, color: Colors.white, size: 16),
                  ),
                  title: Text(category.name),
                  selected: transaction.category == category.id,
                  onTap: () {
                    provider.updateTransactionCategory(
                      transaction.id,
                      category.id,
                    );
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
