// models/command.dart
abstract class Command {
  Future<void> execute();
  Future<void> undo();
  String get description;
}

class AddTransactionCommand extends Command {
  final String transactionId;
  final Map<String, dynamic> transactionData;
  final Function(String) _deleteTransaction;
  final Function(Map<String, dynamic>) _addTransaction;

  AddTransactionCommand({
    required this.transactionId,
    required this.transactionData,
    required Function(String) deleteTransaction,
    required Function(Map<String, dynamic>) addTransaction,
  }) : _deleteTransaction = deleteTransaction,
       _addTransaction = addTransaction;

  @override
  Future<void> execute() async {
    await _addTransaction(transactionData);
  }

  @override
  Future<void> undo() async {
    await _deleteTransaction(transactionId);
  }

  @override
  String get description => 'Add transaction: ${transactionData['description']}';
}

class DeleteTransactionCommand extends Command {
  final String transactionId;
  final Map<String, dynamic> transactionData;
  final Function(String) _deleteTransaction;
  final Function(Map<String, dynamic>) _addTransaction;

  DeleteTransactionCommand({
    required this.transactionId,
    required this.transactionData,
    required Function(String) deleteTransaction,
    required Function(Map<String, dynamic>) addTransaction,
  }) : _deleteTransaction = deleteTransaction,
       _addTransaction = addTransaction;

  @override
  Future<void> execute() async {
    await _deleteTransaction(transactionId);
  }

  @override
  Future<void> undo() async {
    await _addTransaction(transactionData);
  }

  @override
  String get description => 'Delete transaction: ${transactionData['description']}';
}

class UpdateTransactionCommand extends Command {
  final String transactionId;
  final Map<String, dynamic> oldData;
  final Map<String, dynamic> newData;
  final Function(Map<String, dynamic>) _updateTransaction;

  UpdateTransactionCommand({
    required this.transactionId,
    required this.oldData,
    required this.newData,
    required Function(Map<String, dynamic>) updateTransaction,
  }) : _updateTransaction = updateTransaction;

  @override
  Future<void> execute() async {
    await _updateTransaction(newData);
  }

  @override
  Future<void> undo() async {
    await _updateTransaction(oldData);
  }

  @override
  String get description => 'Update transaction: ${newData['description']}';
}

class UpdateTransactionCategoryCommand extends Command {
  final String transactionId;
  final String oldCategoryId;
  final String newCategoryId;
  final Function(String, String) _updateTransactionCategory;

  UpdateTransactionCategoryCommand({
    required this.transactionId,
    required this.oldCategoryId,
    required this.newCategoryId,
    required Function(String, String) updateTransactionCategory,
  }) : _updateTransactionCategory = updateTransactionCategory;

  @override
  Future<void> execute() async {
    await _updateTransactionCategory(transactionId, newCategoryId);
  }

  @override
  Future<void> undo() async {
    await _updateTransactionCategory(transactionId, oldCategoryId);
  }

  @override
  String get description => 'Move transaction to category';
}