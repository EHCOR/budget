// screens/categories_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/category.dart';
import 'settings_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();

  static void showAddCategoryDialog(BuildContext context) {
    _CategoriesPageState._showAddCategoryDialogStatic(context);
  }
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get all available icons for categories with their names
  static Map<String, IconData> get availableIconsMap => {
    // Food & Dining
    'restaurant': Icons.restaurant,
    'cafe': Icons.local_cafe,
    'bar': Icons.local_bar,
    'pizza': Icons.local_pizza,
    'fastfood': Icons.fastfood,
    'bakery': Icons.bakery_dining,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
    'breakfast': Icons.breakfast_dining,
    'wine': Icons.wine_bar,
    'grocery': Icons.local_grocery_store,

    // Shopping
    'shopping cart': Icons.shopping_cart,
    'shopping bag': Icons.shopping_bag,
    'store': Icons.store,
    'mall': Icons.local_mall,
    'storefront': Icons.storefront,
    'shipping': Icons.local_shipping,
    'basket': Icons.shopping_basket,

    // Transportation
    'car': Icons.directions_car,
    'gas station': Icons.local_gas_station,
    'bus': Icons.directions_bus,
    'train': Icons.train,
    'flight': Icons.flight,
    'bike': Icons.directions_bike,
    'motorcycle': Icons.motorcycle,
    'taxi': Icons.local_taxi,
    'subway': Icons.subway,
    'electric car': Icons.electric_car,

    // Home & Utilities
    'home': Icons.home,
    'electrical': Icons.electrical_services,
    'plumbing': Icons.plumbing,
    'thermostat': Icons.thermostat,
    'water': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone': Icons.phone,
    'tv': Icons.tv,
    'cleaning': Icons.cleaning_services,
    'repair': Icons.home_repair_service,

    // Health & Medical
    'medical': Icons.medical_services,
    'hospital': Icons.local_hospital,
    'pharmacy': Icons.local_pharmacy,
    'medication': Icons.medication,
    'psychology': Icons.psychology,
    'spa': Icons.spa,
    'improvement': Icons.self_improvement,
    'medical info': Icons.medical_information,

    // Entertainment
    'movie': Icons.movie,
    'theater': Icons.theater_comedy,
    'music': Icons.music_note,
    'gaming': Icons.sports_esports,
    'soccer': Icons.sports_soccer,
    'basketball': Icons.sports_basketball,
    'park': Icons.park,
    'camera': Icons.camera_alt,
    'books': Icons.library_books,
    'celebration': Icons.celebration,

    // Education & Work
    'school': Icons.school,
    'work': Icons.work,
    'business': Icons.business,
    'computer': Icons.computer,
    'book': Icons.book,
    'menu book': Icons.menu_book,
    'class': Icons.class_,
    'workspace': Icons.workspace_premium,

    // Fitness & Sports
    'fitness': Icons.fitness_center,
    'gymnastics': Icons.sports_gymnastics,
    'pool': Icons.pool,
    'hiking': Icons.hiking,
    'tennis': Icons.sports_tennis,
    'golf': Icons.golf_course,
    'snowboarding': Icons.snowboarding,
    'kayaking': Icons.kayaking,

    // Finance & Business
    'bank': Icons.account_balance,
    'credit card': Icons.credit_card,
    'savings': Icons.savings,
    'paid': Icons.paid,
    'money': Icons.attach_money,
    'currency': Icons.currency_exchange,
    'trending': Icons.trending_up,
    'wallet': Icons.account_balance_wallet,
    'receipt': Icons.receipt_long,
    'calculate': Icons.calculate,

    // Personal Care
    'haircut': Icons.content_cut,
    'face': Icons.face,
    'clothing': Icons.checkroom,
    'laundry': Icons.local_laundry_service,
    'dry cleaning': Icons.dry_cleaning,

    // Pets & Animals
    'pets': Icons.pets,

    // Travel & Vacation
    'takeoff': Icons.flight_takeoff,
    'hotel': Icons.hotel,
    'luggage': Icons.luggage,
    'map': Icons.map,
    'beach': Icons.beach_access,
    'tour': Icons.tour,

    // Technology
    'smartphone': Icons.smartphone,
    'laptop': Icons.laptop,
    'tablet': Icons.tablet,
    'headphones': Icons.headphones,
    'cable': Icons.cable,
    'router': Icons.router,

    // Miscellaneous
    'category': Icons.category,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'gift': Icons.card_giftcard,
    'volunteer': Icons.volunteer_activism,
    'eco': Icons.eco,
    'florist': Icons.local_florist,
    'child care': Icons.child_care,
    'elderly': Icons.elderly,
  };


  List<Category> _filterCategories(List<Category> categories) {
    if (_searchQuery.isEmpty) {
      return categories;
    }

    return categories.where((category) {
      final name = category.name.toLowerCase();
      final keywords = category.keywords.join(' ').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || keywords.contains(query);
    }).toList();
  }

  // Get dialog width based on screen size breakpoints
  double _getDialogWidth(double screenWidth) {
    return _getDialogWidthStatic(screenWidth);
  }

  static double _getDialogWidthStatic(double screenWidth) {
    if (screenWidth < 600) {
      // xs - Small screens (phones)
      return screenWidth * 0.9;
    } else if (screenWidth < 900) {
      // sm/md - Medium screens (tablets)
      return 500;
    } else if (screenWidth < 1200) {
      // lg - Large screens (small laptops)
      return 600;
    } else {
      // xl - Extra large screens (desktops)
      return 700;
    }
  }

  Widget _buildIconPicker(Color selectedColor, IconData selectedIcon, Function(IconData) onIconSelected) {
    return SizedBox(
      height: 240,
      child: _IconPickerWidget(
        selectedColor: selectedColor,
        selectedIcon: selectedIcon,
        onIconSelected: onIconSelected,
      ),
    );
  }

  static Widget _buildIconPickerStatic(Color selectedColor, IconData selectedIcon, Function(IconData) onIconSelected) {
    return SizedBox(
      height: 240,
      child: _IconPickerWidget(
        selectedColor: selectedColor,
        selectedIcon: selectedIcon,
        onIconSelected: onIconSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Categories'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddCategoryDialog(context),
              tooltip: 'Add Category',
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
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
          final allCategories = provider.categories.where((c) => c.id != 'uncategorized').toList();
          final filteredCategories = _filterCategories(allCategories);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
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
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              // Categories list
              Expanded(
                child: filteredCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty ? Icons.category_outlined : Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No categories yet'
                                  : 'No categories found for "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first category',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          final transactionCount = provider.getTransactionsByCategory(category.id).length;
                          final total = provider.getTransactionsByCategory(category.id)
                              .fold(0.0, (sum, t) => sum + t.amount.abs());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: category.color.withValues(alpha: 0.2),
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    CategoriesPage.showAddCategoryDialog(context);
  }

  static void _showAddCategoryDialogStatic(BuildContext context) {
    final nameController = TextEditingController();
    final keywordsController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final screenWidth = MediaQuery.of(context).size.width;
          final dialogWidth = _getDialogWidthStatic(screenWidth);

          return AlertDialog(
            title: const Text('Add Category'),
            content: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
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
                    _buildIconPickerStatic(selectedColor, selectedIcon, (icon) {
                      setState(() => selectedIcon = icon);
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
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
          );
      },
    ));
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    final keywordsController = TextEditingController(text: category.keywords.join(', '));
    Color selectedColor = category.color;
    IconData selectedIcon = category.icon;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final screenWidth = MediaQuery.of(context).size.width;
          final dialogWidth = _getDialogWidth(screenWidth);

          return AlertDialog(
            title: const Text('Edit Category'),
            content: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
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
                    const SizedBox(height: 8),
                  ],
                ),
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
          );
      },
    ));
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

class _IconPickerWidget extends StatefulWidget {
  final Color selectedColor;
  final IconData selectedIcon;
  final Function(IconData) onIconSelected;

  const _IconPickerWidget({
    required this.selectedColor,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  State<_IconPickerWidget> createState() => _IconPickerWidgetState();
}

class _IconPickerWidgetState extends State<_IconPickerWidget> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, IconData>> get _filteredIcons {
    if (_searchQuery.isEmpty) {
      return _CategoriesPageState.availableIconsMap.entries.toList();
    }

    return _CategoriesPageState.availableIconsMap.entries
        .where((entry) => entry.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Select Icon'),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              height: 40,
              child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search icons...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _filteredIcons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No icons found for "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filteredIcons.map((entry) {
                      final icon = entry.value;
                      return Tooltip(
                        message: entry.key,
                        child: GestureDetector(
                          onTap: () => widget.onIconSelected(icon),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: widget.selectedIcon == icon
                                  ? widget.selectedColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: widget.selectedIcon == icon
                                  ? Border.all(color: widget.selectedColor)
                                  : null,
                            ),
                            child: Icon(icon, color: widget.selectedColor, size: 20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}