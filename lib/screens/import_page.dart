// screens/import_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'transactions_page.dart';
// import 'home_page.dart';
import 'dashboard_page.dart';
import '../widgets/nav_bar.dart';

class ImportPage extends StatefulWidget {
  final bool showDrawer;
  
  const ImportPage({super.key, this.showDrawer = true});

  @override
  _ImportPageState createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _isLoading = false;
  String _importMessage = '';
  int _dateColumnIndex = 0;
  int _descriptionColumnIndex = 1;
  int _amountColumnIndex = 2;
  int? _balanceColumnIndex = 3;
  List<List<dynamic>>? _csvPreview;
  List<String>? _headers;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to defer the initialization until after the build is complete
    Future.microtask(() => _initializeData());
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    final provider = Provider.of<TransactionData>(context, listen: false);
    await provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Transactions'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      drawer: widget.showDrawer ? const NavBar() : null,
      body: Consumer<TransactionData>(
        builder: (context, transactionData, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Transactions',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload a CSV file containing your transaction data:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Format: date (YYYYMMDD), description, amount, balance',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isLoading ? null : _pickAndReadCSVFile,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text(
                                      'Select Bank Statement CSV',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    if (_importMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _importMessage.contains('Error') ||
                                      _importMessage.contains('No ')
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _importMessage.contains('Error') ||
                                      _importMessage.contains('No ')
                                  ? Icons.error
                                  : Icons.check_circle,
                              color:
                                  _importMessage.contains('Error') ||
                                          _importMessage.contains('No ')
                                      ? Colors.red
                                      : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _importMessage,
                                style: TextStyle(
                                  color:
                                      _importMessage.contains('Error') ||
                                              _importMessage.contains('No ')
                                          ? Colors.red
                                          : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_csvPreview != null && _headers != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Column Mapping',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildColumnSelector(
                                'Date Column',
                                _dateColumnIndex,
                                (value) =>
                                    setState(() => _dateColumnIndex = value!),
                              ),
                              const SizedBox(height: 12),
                              _buildColumnSelector(
                                'Description Column',
                                _descriptionColumnIndex,
                                (value) => setState(
                                  () => _descriptionColumnIndex = value!,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildColumnSelector(
                                'Amount Column',
                                _amountColumnIndex,
                                (value) =>
                                    setState(() => _amountColumnIndex = value!),
                              ),
                              const SizedBox(height: 12),
                              _buildColumnSelector(
                                'Balance Column (Optional)',
                                _balanceColumnIndex ?? 0,
                                (value) =>
                                    setState(() => _balanceColumnIndex = value),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Note: Negative amounts will be treated as expenses, positive as income',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'CSV Preview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns:
                                  _headers!
                                      .map(
                                        (header) =>
                                            DataColumn(label: Text(header)),
                                      )
                                      .toList(),
                              rows:
                                  _csvPreview!
                                      .sublist(
                                        1,
                                        _csvPreview!.length > 6
                                            ? 6
                                            : _csvPreview!.length,
                                      ) // Show limited preview
                                      .map(
                                        (row) => DataRow(
                                          cells:
                                              row
                                                  .map(
                                                    (cell) => DataCell(
                                                      Text(cell.toString()),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                      ),
                      if (_csvPreview!.length > 6)
                        const Text(
                          'Showing first 5 rows of rows total rows',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),

                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _importTransactions,
                        icon: const Icon(Icons.check),
                        label: const Text('Import Transactions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TransactionsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list),
                        label: const Text('View Transactions'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColumnSelector(
    String label,
    int value,
    Function(int?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withOpacity(0.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        value: value,
        items: List.generate(
          _headers!.length,
          (index) => DropdownMenuItem(
            value: index,
            child: Text('${_headers![index]} (column ${index + 1})'),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _pickAndReadCSVFile() async {
    setState(() {
      _isLoading = true;
      _importMessage = '';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String fileContent = await file.readAsString();

        // Parse CSV
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(
          fileContent,
        );

        if (csvTable.isNotEmpty) {
          setState(() {
            if (_isHeaderRow(csvTable[0])) {
              _headers = csvTable[0].map((item) => item.toString()).toList();
              _csvPreview = csvTable; // Show all rows
            } else {
              _headers = List.generate(
                csvTable[0].length,
                (index) => 'Column ${index + 1}',
              );
              _csvPreview = [_headers!, ...csvTable];
            }
            // Ensure all rows have the same number of cells as the header
            _csvPreview =
                _csvPreview!.map((row) {
                  if (row.length < _headers!.length) {
                    return [
                      ...row,
                      ...List.filled(_headers!.length - row.length, ''),
                    ];
                  } else if (row.length > _headers!.length) {
                    return row.sublist(0, _headers!.length);
                  }
                  return row;
                }).toList();

            // Try to auto-detect columns based on header names
            _autoDetectColumns();
          });
        } else {
          setState(() {
            _importMessage = 'The CSV file is empty';
          });
        }
      }
    } catch (e) {
      setState(() {
        _importMessage = 'Error reading CSV file: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isHeaderRow(List<dynamic> row) {
    // Simple heuristic to check if the row is a header row
    if (row.isEmpty) return false;

    // Check if any cell contains a date-like string
    bool containsDate = row.any((cell) {
      final str = cell.toString().toLowerCase();
      return str.contains('date') || str.contains('time');
    });

    // Check if any cell contains description-like string
    bool containsDescription = row.any((cell) {
      final str = cell.toString().toLowerCase();
      return str.contains('desc') ||
          str.contains('narr') ||
          str.contains('memo');
    });

    // Check if any cell contains amount-like string
    bool containsAmount = row.any((cell) {
      final str = cell.toString().toLowerCase();
      return str.contains('amount') ||
          str.contains('sum') ||
          str.contains('value');
    });

    return containsDate || containsDescription || containsAmount;
  }

  void _autoDetectColumns() {
    if (_headers == null) return;

    // Try to find common header names
    for (int i = 0; i < _headers!.length; i++) {
      String header = _headers![i].toLowerCase();

      // Date column detection
      if (header.contains('date')) {
        _dateColumnIndex = i;
      }
      // Description/narrative column detection
      else if (header.contains('desc') ||
          header.contains('narr') ||
          header.contains('part') ||
          header.contains('memo')) {
        _descriptionColumnIndex = i;
      }
      // Amount column detection
      else if (header.contains('amount') ||
          header.contains('sum') ||
          header.contains('value')) {
        _amountColumnIndex = i;
      }
      // Balance column detection
      else if (header.contains('balance') ||
          header.contains('total') ||
          header.contains('remain')) {
        _balanceColumnIndex = i;
      }
    }
  }

  void _importTransactions() async {
    if (_csvPreview == null || _csvPreview!.isEmpty) {
      setState(() {
        _importMessage = 'No data to import';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _importMessage = '';
    });

    try {
      // Use the already loaded CSV data
      List<List<dynamic>> csvData = _csvPreview!;

      if (csvData.isEmpty) {
        setState(() {
          _importMessage = 'No data found in CSV';
        });
        return;
      }

      // Skip the header row
      List<List<dynamic>> data = csvData.sublist(1);

      List<Transaction> newTransactions = [];

      for (var row in data) {
        if (row.length <=
            [
              _dateColumnIndex,
              _descriptionColumnIndex,
              _amountColumnIndex,
            ].reduce((max, index) => index > max ? index : max)) {
          continue; // Skip rows that don't have enough columns
        }

        // Parse date - handle YYYYMMDD format specifically
        DateTime date;
        try {
          String dateStr = row[_dateColumnIndex].toString();

          // Try YYYYMMDD format first (common for bank statements)
          if (dateStr.length == 8 && int.tryParse(dateStr) != null) {
            int year = int.parse(dateStr.substring(0, 4));
            int month = int.parse(dateStr.substring(4, 6));
            int day = int.parse(dateStr.substring(6, 8));
            date = DateTime(year, month, day);
          }
          // Try other common formats
          else {
            try {
              date = DateFormat('yyyy-MM-dd').parse(dateStr);
            } catch (e) {
              try {
                date = DateFormat('MM/dd/yyyy').parse(dateStr);
              } catch (e) {
                try {
                  date = DateFormat('dd/MM/yyyy').parse(dateStr);
                } catch (e) {
                  // If all parsing attempts fail, skip this row
                  continue;
                }
              }
            }
          }
        } catch (e) {
          // Skip rows with invalid dates
          continue;
        }

        // Parse amount
        double amount;
        try {
          String amountStr = row[_amountColumnIndex]
              .toString()
              .replaceAll('\$', '')
              .replaceAll(',', '')
              .replaceAll(' ', '');
          amount = double.parse(amountStr);
        } catch (e) {
          continue; // Skip rows with invalid amounts
        }

        // Parse balance (if available)
        double balance = 0.0;
        if (row.length > 3 && _balanceColumnIndex != null) {
          try {
            String balanceStr = row[_balanceColumnIndex!]
                .toString()
                .replaceAll('\$', '')
                .replaceAll(',', '')
                .replaceAll(' ', '');
            balance = double.parse(balanceStr);
          } catch (e) {
            // Just use 0 if balance is not valid
          }
        }

        // Get the description, clean it up
        String description = row[_descriptionColumnIndex].toString();
        // Remove quotes if present (sometimes CSVs have quoted strings)
        description = description.replaceAll('"', '');

        // Create transaction with proper type based on amount
        final type =
            amount >= 0 ? TransactionType.income : TransactionType.expense;

        newTransactions.add(
          Transaction(
            date: date,
            description: description,
            amount: amount,
            balance: balance,
            category: 'Uncategorized',
            type: type,
          ),
        );
      }

      // Add transactions to the provider
      if (newTransactions.isNotEmpty) {
        await Provider.of<TransactionData>(
          context,
          listen: false,
        ).addTransactions(newTransactions);

        setState(() {
          _importMessage =
              'Successfully imported ${newTransactions.length} transactions';
        });

        // Go back to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        setState(() {
          _importMessage = 'No valid transactions found in the CSV';
        });
      }
    } catch (e) {
      setState(() {
        _importMessage = 'Error importing transactions: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
