// utils/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';

class StorageService {
  static Future<String> _getTransactionsFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/transactions.json';
  }

  // Save transactions to a JSON file
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    try {
      final filePath = await _getTransactionsFilePath();
      final file = File(filePath);
      
      // Convert transactions to a list of JSON objects
      final jsonData = transactions.map((t) => t.toJson()).toList();
      
      // Save as JSON
      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      throw Exception('Failed to save transactions: $e');
    }
  }

  // Load transactions from the JSON file
  static Future<List<Transaction>> loadTransactions() async {
    try {
      final filePath = await _getTransactionsFilePath();
      final file = File(filePath);
      
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as List;
      
      return jsonData.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      // If loading fails, return an empty list
      return [];
    }
  }

  // Delete all transaction data
  static Future<void> deleteAllTransactions() async {
    try {
      final filePath = await _getTransactionsFilePath();
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete transactions: $e');
    }
  }

  // Backup all data to a file
  static Future<String> backupData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create();
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${backupDir.path}/backup_$timestamp.json';
      
      // Copy the transactions file to the backup
      final transactionsFile = File(await _getTransactionsFilePath());
      if (await transactionsFile.exists()) {
        await transactionsFile.copy(backupPath);
      }
      
      return backupPath;
    } catch (e) {
      throw Exception('Failed to backup data: $e');
    }
  }

  // Restore data from a backup file
  static Future<void> restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }
      
      final transactionsPath = await _getTransactionsFilePath();
      await backupFile.copy(transactionsPath);
    } catch (e) {
      throw Exception('Failed to restore from backup: $e');
    }
  }
  
  // Get settings file path
  static Future<String> _getSettingsFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/settings.json';
  }
  
  // Load settings
  static Future<Map<String, dynamic>?> loadSettings() async {
    try {
      final filePath = await _getSettingsFilePath();
      final file = File(filePath);
      
      if (!await file.exists()) {
        return null;
      }
      
      final jsonString = await file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  // Save settings
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final filePath = await _getSettingsFilePath();
      final file = File(filePath);
      
      await file.writeAsString(jsonEncode(settings));
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }
}