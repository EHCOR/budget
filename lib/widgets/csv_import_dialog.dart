// widgets/csv_import_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class CsvImportDialog extends StatefulWidget {
  const CsvImportDialog({super.key});

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  final _csvController = TextEditingController();
  bool _isProcessing = false;
  String? _previewText;
  List<Transaction>? _parsedTransactions;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import CSV Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              const Text(
                'Paste your CSV data here. Expected format:\n'
                    'Date (YYYYMMDD), Description, Amount',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _csvController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Paste CSV data here...\n'
                      'Example:\n'
                      '20240101,Grocery Store,-45.50\n'
                      '20240102,Salary,2500.00',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              if (_previewText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    _previewText!,
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  if (_parsedTransactions == null)
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _parseCSV,
                      child: _isProcessing
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Parse CSV'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _importTransactions,
                      child: const Text('Import'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _parseCSV() {
    if (_csvController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste CSV data')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _previewText = null;
      _parsedTransactions = null;
    });

    try {
      final csvString = _csvController.text.trim();
      final csvTable = const CsvToListConverter().convert(csvString);

      if (csvTable.isEmpty) {
        throw Exception('No data found in CSV');
      }

      // Check if first row is header
      final hasHeader = _isHeaderRow(csvTable[0]);
      final dataRows = hasHeader ? csvTable.sublist(1) : csvTable;

      // Parse transactions
      final transactions = <Transaction>[];
      int skippedRows = 0;

      for (var row in dataRows) {
        final transaction = Transaction.fromCsvRow(row);
        if (transaction != null) {
          transactions.add(transaction);
        } else {
          skippedRows++;
        }
      }

      if (transactions.isEmpty) {
        throw Exception('No valid transactions found');
      }

      setState(() {
        _parsedTransactions = transactions;
        _previewText = 'Found ${transactions.length} valid transactions'
            '${skippedRows > 0 ? ' (skipped $skippedRows invalid rows)' : ''}';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _previewText = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing CSV: ${e.toString()}')),
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
      // If it's 8 digits, likely a date in YYYYMMDD format
      if (firstCell.length == 8 && int.tryParse(firstCell) != null) {
        return false;
      }
      // If it contains only letters, likely a header
      if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(firstCell)) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> _importTransactions() async {
    if (_parsedTransactions == null || _parsedTransactions!.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final results = await provider.addTransactions(_parsedTransactions!);

      if (mounted) {
        Navigator.pop(context);

        final importedCount = results['imported'] ?? 0;
        final duplicateCount = results['duplicates'] ?? 0;

        String message;
        Color backgroundColor = Colors.green;

        if (duplicateCount > 0) {
          message = 'Imported $importedCount transactions, skipped $duplicateCount duplicate transactions';
          backgroundColor = Colors.orange;
        } else {
          message = 'Imported $importedCount transactions';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing: ${e.toString()}')),
      );
    }
  }
}