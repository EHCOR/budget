// screens/settings_page.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import '../providers/transaction_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'ZAR', 'symbol': 'R', 'name': 'South African Rand'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Currency section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Currency',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select your preferred currency',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: provider.currencyCode,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: currencies.map((currency) {
                          return DropdownMenuItem(
                            value: currency['code'],
                            child: Text('${currency['symbol']} ${currency['name']}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final currency = currencies.firstWhere((c) => c['code'] == value);
                            provider.setCurrency(value, currency['symbol']!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Theme section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Theme',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose your preferred theme',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: const Text('Light'),
                            secondary: const Icon(Icons.light_mode),
                            value: ThemeMode.light,
                            groupValue: provider.themeMode,
                            onChanged: (value) {
                              if (value != null) provider.setThemeMode(value);
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('Dark'),
                            secondary: const Icon(Icons.dark_mode),
                            value: ThemeMode.dark,
                            groupValue: provider.themeMode,
                            onChanged: (value) {
                              if (value != null) provider.setThemeMode(value);
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('System Default'),
                            secondary: const Icon(Icons.settings_suggest),
                            value: ThemeMode.system,
                            groupValue: provider.themeMode,
                            onChanged: (value) {
                              if (value != null) provider.setThemeMode(value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data management section
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Export Data'),
                      subtitle: const Text('Save a backup of your data'),
                      onTap: () => _exportData(context, provider),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.upload),
                      title: const Text('Import Data'),
                      subtitle: const Text('Restore from a backup'),
                      onTap: () => _importData(context, provider),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                      subtitle: const Text('Delete all transactions and reset categories'),
                      onTap: () => _confirmClearData(context, provider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // About section
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('Version 2.0.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Budget Tracker',
                      applicationVersion: '2.0.0',
                      applicationLegalese: '© 2024 Budget Tracker',
                      children: const [
                        SizedBox(height: 16),
                        Text('A simple and efficient app to track your personal finances.'),
                      ],
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

  void _exportData(BuildContext context, TransactionProvider provider) async {
    final exportData = await provider.exportDataAsJson();
    final bytes = utf8.encode(exportData);
    final date = DateTime.now().toIso8601String().substring(0, 10);

    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'budget_tracker_backup_$date.json')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'budget_tracker_backup_$date.json',
      );

      if (outputFile != null) {
        // User selected a file
      }
    }
  }

  void _importData(BuildContext context, TransactionProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final jsonString = utf8.decode(bytes);
      final success = await provider.importDataFromJson(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Data imported successfully' : 'Failed to import data'),
          ),
        );
      }
    }
  }

  void _confirmClearData(BuildContext context, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your transactions and reset categories to default.\n\n'
              'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data has been cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
