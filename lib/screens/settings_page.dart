// screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nav_bar.dart';

class SettingsPage extends StatefulWidget {
  final bool showDrawer;
  
  const SettingsPage({super.key, this.showDrawer = true});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'ZAR', 'symbol': 'R', 'name': 'South African Rand'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'BRL', 'symbol': 'R\$', 'name': 'Brazilian Real'},
    {'code': 'RUB', 'symbol': '₽', 'name': 'Russian Ruble'},
  ];

  late String _selectedCurrency;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionData>(context);
    _selectedCurrency = provider.currencyCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      drawer: widget.showDrawer ? const NavBar() : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),

            // Currency selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the currency to use throughout the app.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                      ),
                      items:
                          _currencies
                              .map(
                                (currency) => DropdownMenuItem(
                                  value: currency['code'],
                                  child: Text(
                                    '${currency['code']} (${currency['symbol']}) - ${currency['name']}',
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });

                          // Get the symbol for the selected currency
                          final currencyMap = _currencies.firstWhere(
                            (currency) => currency['code'] == value,
                            orElse:
                                () => {
                                  'code': 'USD',
                                  'symbol': '\$',
                                  'name': 'US Dollar',
                                },
                          );

                          // Update the provider
                          provider.setCurrency(
                            value,
                            currencyMap['symbol'] ?? '\$',
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Currency updated successfully'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Theme mode
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose the app theme.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final themeMode = provider.themeMode;

                        return Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              title: const Text('Light Mode'),
                              value: ThemeMode.light,
                              groupValue: themeMode,
                              onChanged: (ThemeMode? value) {
                                if (value != null) {
                                  provider.setThemeMode(value);
                                }
                              },
                              secondary: const Icon(Icons.light_mode),
                            ),
                            RadioListTile<ThemeMode>(
                              title: const Text('Dark Mode'),
                              value: ThemeMode.dark,
                              groupValue: themeMode,
                              onChanged: (ThemeMode? value) {
                                if (value != null) {
                                  provider.setThemeMode(value);
                                }
                              },
                              secondary: const Icon(Icons.dark_mode),
                            ),
                            RadioListTile<ThemeMode>(
                              title: const Text('System Default'),
                              value: ThemeMode.system,
                              groupValue: themeMode,
                              onChanged: (ThemeMode? value) {
                                if (value != null) {
                                  provider.setThemeMode(value);
                                }
                              },
                              secondary: const Icon(Icons.settings_suggest),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Data management
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Clear All Data'),
                subtitle: const Text('Remove all transactions and categories'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Clear All Data?'),
                          content: const Text(
                            'This will permanently delete all your transactions and categories. This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Provider.of<TransactionData>(
                                  context,
                                  listen: false,
                                ).clearTransactions();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('All data has been cleared'),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete All'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // About section
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: const Text('Version 1.1.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Budget Tracker',
                    applicationVersion: '1.1.0',
                    applicationLegalese: '© 2023-2025 Budget Tracker App',
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'A simple app to track your expenses and visualize your spending patterns.',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
