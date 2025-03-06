// widgets/nav_bar.dart
import 'package:flutter/material.dart';
import '../screens/dashboard_page.dart';
import '../screens/transactions_page.dart';
import '../screens/import_page.dart';
import '../screens/settings_page.dart';
import '../screens/categories_page.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'package:intl/intl.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildNavItem(
                  context,
                  title: 'Dashboard',
                  icon: Icons.dashboard,
                  destination: DashboardPage(),
                ),
                _buildNavItem(
                  context,
                  title: 'Transactions',
                  icon: Icons.receipt_long,
                  destination: TransactionsPage(),
                ),
                _buildNavItem(
                  context,
                  title: 'Categories',
                  icon: Icons.category,
                  destination: CategoriesPage(),
                ),
                _buildNavItem(
                  context,
                  title: 'Import Data',
                  icon: Icons.upload_file,
                  destination: ImportPage(),
                ),
                _buildNavItem(
                  context,
                  title: 'Settings',
                  icon: Icons.settings,
                  destination: SettingsPage(),
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<TransactionData>(
      builder: (context, data, child) {
        final totalBalance =
            data.transactions.isNotEmpty ? data.transactions.last.balance : 0.0;

        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            16 + MediaQuery.of(context).padding.top,
            16,
            16,
          ),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget Tracker',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              if (data.transactions.isNotEmpty) ...[
                Text(
                  'Current Balance',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  NumberFormat.currency(symbol: '\$').format(totalBalance),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget destination,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = destination.runtimeType.toString() == currentRoute;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (destination.runtimeType.toString() != currentRoute) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => destination,
              settings: RouteSettings(name: destination.runtimeType.toString()),
            ),
          );
        }
      },
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    return Consumer<TransactionData>(
      builder: (context, data, child) {
        if (data.categories.isEmpty) {
          return ListTile(
            title: Text('No categories'),
            subtitle: Text('Import data to get started'),
            leading: Icon(Icons.category_outlined),
          );
        }

        // Take just top categories to avoid the list being too long
        final topCategories = data.categories.take(8).toList();

        return Column(
          children:
              topCategories.map((category) {
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: category.color.withOpacity(0.2),
                    child: Icon(category.icon, color: category.color, size: 16),
                    radius: 14,
                  ),
                  title: Text(category.name),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TransactionsPage(
                              initialCategoryId: category.id,
                            ),
                      ),
                    );
                  },
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Divider(),
          ListTile(
            title: Text('App Version'),
            subtitle: Text('1.1.0'),
            leading: Icon(Icons.info_outline),
            dense: true,
          ),
        ],
      ),
    );
  }
}
