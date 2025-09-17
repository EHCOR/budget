// screens/categories_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/category.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  // Get all available icons for categories
  static List<IconData> get availableIcons => [
    // Food & Dining
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.local_pizza,
    Icons.fastfood,
    Icons.bakery_dining,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.breakfast_dining,
    Icons.wine_bar,
    Icons.local_grocery_store,

    // Shopping
    Icons.shopping_cart,
    Icons.shopping_bag,
    Icons.store,
    Icons.local_mall,
    Icons.storefront,
    Icons.local_shipping,
    Icons.shopping_basket,

    // Transportation
    Icons.directions_car,
    Icons.local_gas_station,
    Icons.directions_bus,
    Icons.train,
    Icons.flight,
    Icons.directions_bike,
    Icons.motorcycle,
    Icons.local_taxi,
    Icons.subway,
    Icons.electric_car,

    // Home & Utilities
    Icons.home,
    Icons.electrical_services,
    Icons.plumbing,
    Icons.thermostat,
    Icons.water_drop,
    Icons.wifi,
    Icons.phone,
    Icons.tv,
    Icons.cleaning_services,
    Icons.home_repair_service,

    // Health & Medical
    Icons.medical_services,
    Icons.local_hospital,
    Icons.local_pharmacy,
    Icons.medication,
    Icons.psychology,
    Icons.spa,
    Icons.self_improvement,
    Icons.medical_information,

    // Entertainment
    Icons.movie,
    Icons.theater_comedy,
    Icons.music_note,
    Icons.sports_esports,
    Icons.sports_soccer,
    Icons.sports_basketball,
    Icons.park,
    Icons.camera_alt,
    Icons.library_books,
    Icons.celebration,

    // Education & Work
    Icons.school,
    Icons.work,
    Icons.business,
    Icons.computer,
    Icons.book,
    Icons.menu_book,
    Icons.class_,
    Icons.workspace_premium,

    // Fitness & Sports
    Icons.fitness_center,
    Icons.sports_gymnastics,
    Icons.pool,
    Icons.hiking,
    Icons.sports_tennis,
    Icons.golf_course,
    Icons.snowboarding,
    Icons.kayaking,

    // Finance & Business
    Icons.account_balance,
    Icons.credit_card,
    Icons.savings,
    Icons.paid,
    Icons.attach_money,
    Icons.currency_exchange,
    Icons.trending_up,
    Icons.account_balance_wallet,
    Icons.receipt_long,
    Icons.calculate,

    // Personal Care
    Icons.content_cut,
    Icons.face,
    Icons.checkroom,
    Icons.local_laundry_service,
    Icons.dry_cleaning,

    // Pets & Animals
    Icons.pets,

    // Travel & Vacation
    Icons.flight_takeoff,
    Icons.hotel,
    Icons.luggage,
    Icons.map,
    Icons.beach_access,
    Icons.tour,

    // Technology
    Icons.smartphone,
    Icons.laptop,
    Icons.tablet,
    Icons.headphones,
    Icons.cable,
    Icons.router,

    // Miscellaneous
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.card_giftcard,
    Icons.volunteer_activism,
    Icons.eco,
    Icons.local_florist,
    Icons.child_care,
    Icons.elderly,
  ];

  Widget _buildIconPicker(Color selectedColor, IconData selectedIcon, Function(IconData) onIconSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Icon'),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableIcons.map((icon) {
                return GestureDetector(
                  onTap: () => onIconSelected(icon),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selectedIcon == icon
                          ? selectedColor.withOpacity(0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: selectedIcon == icon
                          ? Border.all(color: selectedColor)
                          : null,
                    ),
                    child: Icon(icon, color: selectedColor, size: 20),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories.where((c) => c.id != 'uncategorized').toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final transactionCount = provider.getTransactionsByCategory(category.id).length;
              final total = provider.getTransactionsByCategory(category.id)
                  .fold(0.0, (sum, t) => sum + t.amount.abs());

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.color.withOpacity(0.2),
                    child: Icon(category.icon, color: category.color),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$transactionCount transactions • ${provider.currencySymbol}${total.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditCategoryDialog(context, category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, provider, category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final keywordsController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: keywordsController,
                  decoration: const InputDecoration(
                    labelText: 'Keywords (comma separated)',
                    hintText: 'e.g., grocery, food, market',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Color picker
                const Text('Select Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.red,
                    Colors.orange,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                    Colors.teal,
                    Colors.pink,
                    Colors.brown,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Icon picker
                _buildIconPicker(selectedColor, selectedIcon, (icon) {
                  setState(() => selectedIcon = icon);
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final provider = Provider.of<TransactionProvider>(context, listen: false);
                  final keywords = keywordsController.text
                      .split(',')
                      .map((k) => k.trim())
                      .where((k) => k.isNotEmpty)
                      .toList();

                  final matchingCount = provider.countTransactionsByKeywords(keywords);

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Category'),
                      content: Text(
                        'This category will match $matchingCount existing uncategorized transactions. Do you want to proceed?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    final category = Category(
                      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text,
                      color: selectedColor,
                      icon: selectedIcon,
                      keywords: keywords,
                    );

                    await provider.addCategory(category);
                    final recategorizedCount = await provider.recategorizeTransactionsByKeywords(category.id, keywords);
                    if (context.mounted) {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Category "${category.name}" added and $recategorizedCount transactions categorized')),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    final keywordsController = TextEditingController(text: category.keywords.join(', '));
    Color selectedColor = category.color;
    IconData selectedIcon = category.icon;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: keywordsController,
                  decoration: const InputDecoration(
                    labelText: 'Keywords (comma separated)',
                    hintText: 'e.g., grocery, food, market',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Color picker
                const Text('Select Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.red,
                    Colors.orange,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                    Colors.teal,
                    Colors.pink,
                    Colors.brown,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor.value == color.value
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Icon picker
                _buildIconPicker(selectedColor, selectedIcon, (icon) {
                  setState(() => selectedIcon = icon);
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final provider = Provider.of<TransactionProvider>(context, listen: false);
                  final keywords = keywordsController.text
                      .split(',')
                      .map((k) => k.trim())
                      .where((k) => k.isNotEmpty)
                      .toList();

                  // Calculate the impact of changes
                  final changes = provider.calculateCategoryChanges(category, keywords);
                  final totalChanges = changes['added']! + changes['removed']!;

                  bool proceed = true;
                  if (totalChanges > 0) {
                    proceed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Changes'),
                        content: Text(
                          'This update will:\n'
                          '• Add ${changes['added']} transactions to this category\n'
                          '• Remove ${changes['removed']} transactions from this category\n\n'
                          'Do you want to proceed?'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ) ?? false;
                  }

                  if (proceed) {
                    final updatedCategory = Category(
                      id: category.id,
                      name: nameController.text,
                      color: selectedColor,
                      icon: selectedIcon,
                      keywords: keywords,
                    );

                    await provider.updateCategory(updatedCategory);
                    final actualChanges = await provider.updateCategoryAndRecategorize(updatedCategory, keywords);
                    if (context.mounted) {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Category "${updatedCategory.name}" updated: ${actualChanges['added']} added, ${actualChanges['removed']} removed')),
                      );
                    }
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TransactionProvider provider, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\n'
              'All transactions in this category will be marked as uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCategory(category.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Category "${category.name}" deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}