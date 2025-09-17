// screens/home_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import 'dashboard_page.dart';
import 'transactions_page.dart';
import 'trends_page.dart';
import 'categories_page.dart';
import 'settings_page.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/csv_import_dialog.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const TransactionsPage(),
    const TrendsPage(),
    const CategoriesPage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Transactions',
    'Trends',
    'Categories',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Trends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget? _buildFAB() {
    // Show FAB only on dashboard and transactions pages
    if (_selectedIndex == 0 || _selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: _showAddOptions,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAddOption(
                      icon: Icons.edit,
                      label: 'Manual Entry',
                      onTap: () {
                        Navigator.pop(context);
                        _showManualEntryDialog();
                      },
                    ),
                    _buildAddOption(
                      icon: Icons.upload_file,
                      label: 'Import CSV',
                      onTap: () {
                        Navigator.pop(context);
                        _importCSV();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddTransactionDialog(),
    );
  }

  Future<void> _importCSV() async {
    // Show choice dialog for web vs file picker
    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux) {
      // Try file picker for native platforms
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (result != null && result.files.single.bytes != null) {
          final bytes = result.files.single.bytes!;
          final csvString = utf8.decode(bytes);

          _processCSVString(csvString);
        }
      } catch (e) {
        // If file picker fails, fall back to text input
        _showCSVImportDialog();
      }
    } else {
      // For web, use text input dialog
      _showCSVImportDialog();
    }
  }

  void _showCSVImportDialog() {
    showDialog(
      context: context,
      builder: (context) => const CsvImportDialog(),
    );
  }

    void _processCSVString(String csvString) {
    debugPrint('--- Processing CSV String ---');
    debugPrint(csvString);
    debugPrint('--------------------------');
    try {
      // Use a robust CSV converter
      final csvTable = const CsvToListConverter(
        fieldDelimiter: ",",
        textDelimiter: '"',
        eol: '\n',
        allowInvalid: true, // Skip invalid rows
        shouldParseNumbers: false, // We will parse numbers manually
      ).convert(csvString);

      debugPrint('--- CSV Table ---');
      debugPrint(csvTable.toString());
      debugPrint('-----------------');


      if (csvTable.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV file is empty')),
        );
        return;
      }

      // Try to detect if first row is header
      final hasHeader = _isHeaderRow(csvTable[0]);
      final dataRows = hasHeader ? csvTable.sublist(1) : csvTable;

      debugPrint('--- Data Rows ---');
      debugPrint(dataRows.toString());
      debugPrint('-----------------');

      // Parse transactions
      final transactions = <Transaction>[];
      for (var row in dataRows) {
        final transaction = Transaction.fromCsvRow(row);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid transactions found in CSV')),
        );
        return;
      }

      // Add transactions
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      provider.addTransactions(transactions);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${transactions.length} transactions')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing CSV: $e')),
      );
    }
  }

  bool _isHeaderRow(List<dynamic> row) {
    if (row.isEmpty) return false;

    // Check if any cell contains common header words
    for (var cell in row) {
      final str = cell.toString().toLowerCase();
      if (str.contains('date') ||
          str.contains('description') ||
          str.contains('amount') ||
          str.contains('balance')) {
        return true;
      }
    }

    // Check if first cell doesn't parse as a date
    try {
      final firstCell = row[0].toString();
      if (firstCell.length == 8 && int.tryParse(firstCell) != null) {
        return false; // Likely a date in YYYYMMDD format
      }
    } catch (_) {}

    return false;
  }
}