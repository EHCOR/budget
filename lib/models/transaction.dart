// models/transaction.dart
import 'package:intl/intl.dart';

enum TransactionType { expense, income, transfer }

class Transaction {
  final DateTime date;
  final String description;
  final double amount;
  final double balance;
  String category;
  final TransactionType type;
  final String id; // Unique identifier for transactions

  Transaction({
    required this.date,
    required this.description,
    required this.amount,
    this.balance = 0.0,
    this.category = 'Uncategorized',
    TransactionType? type,
    String? id,
  }) : type =
           type ??
           (amount < 0 ? TransactionType.expense : TransactionType.income),
       id =
           id ??
           DateTime.now().millisecondsSinceEpoch.toString() +
               description.hashCode.toString();

  // Create from CSV row data
  factory Transaction.fromCsv(List<String> row) {
    // Assumes format: date, description, amount, balance
    // date format is yyyymmdd
    DateTime date;
    try {
      final dateString = row[0];
      if (dateString.length >= 8) {
        final year = int.parse(dateString.substring(0, 4));
        final month = int.parse(dateString.substring(4, 6));
        final day = int.parse(dateString.substring(6, 8));
        date = DateTime(year, month, day);
      } else {
        date = DateTime.now();
      }
    } catch (e) {
      date = DateTime.now();
    }

    return Transaction(
      date: date,
      description: row[1],
      amount: double.parse(row[2]),
      balance: double.parse(row[3]),
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': DateFormat('yyyyMMdd').format(date),
      'description': description,
      'amount': amount,
      'balance': balance,
      'category': category,
      'type': type.toString().split('.').last, // Store enum as string
    };
  }

  // Create from stored JSON data
  factory Transaction.fromJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      final dateString = json['date'] as String;
      if (dateString.length >= 8) {
        final year = int.parse(dateString.substring(0, 4));
        final month = int.parse(dateString.substring(4, 6));
        final day = int.parse(dateString.substring(6, 8));
        date = DateTime(year, month, day);
      } else {
        date = DateTime.now();
      }
    } catch (e) {
      date = DateTime.now();
    }

    // Handle numeric conversions safely
    double parseAmount() {
      var amount = json['amount'];
      if (amount is int) {
        return amount.toDouble();
      } else if (amount is double) {
        return amount;
      }
      return 0.0;
    }

    double parseBalance() {
      var balance = json['balance'];
      if (balance is int) {
        return balance.toDouble();
      } else if (balance is double) {
        return balance;
      }
      return 0.0;
    }

    return Transaction(
      id: json['id'],
      date: date,
      description: json['description'],
      amount: parseAmount(),
      balance: parseBalance(),
      category: json['category'] ?? 'Uncategorized',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse:
            () =>
                json['amount'] < 0
                    ? TransactionType.expense
                    : TransactionType.income,
      ),
    );
  }

  // Clone with new category
  Transaction copyWith({String? newCategory}) {
    return Transaction(
      id: id,
      date: date,
      description: description,
      amount: amount,
      balance: balance,
      category: newCategory ?? category,
      type: type,
    );
  }
}
