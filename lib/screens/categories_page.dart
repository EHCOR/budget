// screens/categories_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nav_bar.dart';
import 'transactions_page.dart';
import '../models/category_summary.dart';

class CategoriesPage extends StatefulWidget {
  final bool showDrawer;
  
  const CategoriesPage({super.key, this.showDrawer = true});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
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
            tooltip: 'Add Category',
          ),
        ],
      ),
      drawer: widget.showDrawer ? const NavBar() : null,
      body: Consumer<TransactionData>(
        builder: (context, data, child) {
          if (data.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (data.categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No categories found',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Import transactions or add categories manually',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          // Sort categories alphabetically
          final sortedCategories = List.from(data.categories)
            ..sort((a, b) => a.name.compareTo(b.name));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              
              // Get transactions for this category
              final categoryTransactions = data.getTransactionsByCategory(category.id);
              final txCount = categoryTransactions.length;
              
              // Calculate total amount for this category
              final totalAmount = categoryTransactions.fold(
                0.0, 
                (sum, tx) => sum + tx.amount.abs()
              );
              
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
                  subtitle: Text(
                    txCount > 0 
                      ? '$txCount transactions, ${data.currencySymbol}${totalAmount.toStringAsFixed(2)}' 
                      : 'No transactions',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditCategoryDialog(context, category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteCategoryDialog(context, category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionsPage(
                                initialCategoryId: category.id,
                              ),
                            ),
                          );
                        },
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
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                    const Text('Select Color'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Colors.red,
                        Colors.orange,
                        Colors.amber,
                        Colors.green,
                        Colors.teal,
                        Colors.blue,
                        Colors.indigo,
                        Colors.purple,
                        Colors.pink,
                        Colors.brown,
                        Colors.grey,
                        Colors.blueGrey,
                      ].map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: color == selectedColor
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Icon'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Icons.home,
                        Icons.fastfood,
                        Icons.shopping_cart,
                        Icons.directions_car,
                        Icons.local_hospital,
                        Icons.school,
                        Icons.sports_basketball,
                        Icons.movie,
                        Icons.attach_money,
                        Icons.flight,
                        Icons.work,
                        Icons.devices,
                        Icons.local_grocery_store,
                        Icons.fitness_center,
                        Icons.category,
                      ].map((icon) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: icon == selectedIcon
                                  ? selectedColor.withOpacity(0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: icon == selectedIcon
                                  ? Border.all(color: selectedColor, width: 1)
                                  : null,
                            ),
                            child: Icon(icon, color: selectedColor),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a category name'),
                        ),
                      );
                      return;
                    }
                    
                    final provider = Provider.of<TransactionData>(
                      context, 
                      listen: false
                    );
                    
                    provider.addCategory(
                      Category(
                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        color: selectedColor,
                        icon: selectedIcon,
                        tags: [],
                      ),
                    );
                    
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Category "${nameController.text.trim()}" added'),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final TextEditingController nameController = TextEditingController(text: category.name);
    Color selectedColor = category.color;
    IconData selectedIcon = category.icon;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                    const Text('Select Color'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Colors.red,
                        Colors.orange,
                        Colors.amber,
                        Colors.green,
                        Colors.teal,
                        Colors.blue,
                        Colors.indigo,
                        Colors.purple,
                        Colors.pink,
                        Colors.brown,
                        Colors.grey,
                        Colors.blueGrey,
                      ].map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: color.value == selectedColor.value
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Icon'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Icons.home,
                        Icons.fastfood,
                        Icons.shopping_cart,
                        Icons.directions_car,
                        Icons.local_hospital,
                        Icons.school,
                        Icons.sports_basketball,
                        Icons.movie,
                        Icons.attach_money,
                        Icons.flight,
                        Icons.work,
                        Icons.devices,
                        Icons.local_grocery_store,
                        Icons.fitness_center,
                        Icons.category,
                      ].map((icon) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: icon == selectedIcon
                                  ? selectedColor.withOpacity(0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: icon == selectedIcon
                                  ? Border.all(color: selectedColor, width: 1)
                                  : null,
                            ),
                            child: Icon(icon, color: selectedColor),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a category name'),
                        ),
                      );
                      return;
                    }
                    
                    final provider = Provider.of<TransactionData>(
                      context, 
                      listen: false
                    );
                    
                    provider.updateCategory(
                      Category(
                        id: category.id,
                        name: nameController.text.trim(),
                        color: selectedColor,
                        icon: selectedIcon,
                        tags: category.tags,
                      ),
                    );
                    
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Category "${nameController.text.trim()}" updated'),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showDeleteCategoryDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            'Are you sure you want to delete the category "${category.name}"? '
            'All transactions in this category will be marked as "Uncategorized".'
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
                
                provider.deleteCategory(category.id);
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "${category.name}" deleted'),
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
}