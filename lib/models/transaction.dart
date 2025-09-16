// models/transaction.dart
import 'package:intl/intl.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  String categoryId;
  final TransactionType type;

  Transaction({
    String? id,
    required this.date,
    required this.description,
    required this.amount,
    this.categoryId = 'uncategorized',
    TransactionType? type,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type = type ?? (amount >= 0 ? TransactionType.income : TransactionType.expense);

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'categoryId': categoryId,
      'type': type.toString().split('.').last,
    };
  }

  // Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] ?? 'uncategorized',
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
    );
  }

  // Create from CSV row
  static Transaction? fromCsvRow(List<dynamic> row, {
    int dateIndex = 0,
    int descriptionIndex = 1,
    int amountIndex = 2,
  }) {
    try {
      // Parse date (try multiple formats)
      DateTime date;
      String dateStr = row[dateIndex].toString().trim();

      // Try YYYYMMDD format
      if (dateStr.length == 8 && int.tryParse(dateStr) != null) {
        date = DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
        );
      } else {
        // Try other common formats
        try {
          date = DateFormat('yyyy-MM-dd').parse(dateStr);
        } catch (_) {
          try {
            date = DateFormat('MM/dd/yyyy').parse(dateStr);
          } catch (_) {
            try {
              date = DateFormat('dd/MM/yyyy').parse(dateStr);
            } catch (_) {
              return null; // Can't parse date
            }
          }
        }
      }

      // Parse amount
      String amountStr = row[amountIndex].toString()
          .replaceAll(RegExp(r'[^\d.-]'), ''); // Remove currency symbols
      double amount = double.parse(amountStr);

      // Get description
      String description = row[descriptionIndex].toString().trim();

      return Transaction(
        date: date,
        description: description,
        amount: amount,
      );
    } catch (e) {
      print('Error parsing CSV row: $e');
      return null;
    }
  }

  // Copy with modifications
  Transaction copyWith({
    DateTime? date,
    String? description,
    double? amount,
    String? categoryId,
    TransactionType? type,
  }) {
    return Transaction(
      id: id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
    );
  }
}