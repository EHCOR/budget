// providers/undo_redo_provider.dart
import 'package:flutter/material.dart';
import '../models/command.dart';

class UndoRedoProvider extends ChangeNotifier {
  static const int maxHistorySize = 50;

  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  // Getters
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  String? get undoDescription => canUndo ? _undoStack.last.description : null;
  String? get redoDescription => canRedo ? _redoStack.last.description : null;

  int get undoStackSize => _undoStack.length;
  int get redoStackSize => _redoStack.length;

  // Execute a command and add it to the undo stack
  Future<void> executeCommand(Command command) async {
    await command.execute();

    // Add to undo stack
    _undoStack.add(command);

    // Clear redo stack when a new command is executed
    _redoStack.clear();

    // Limit stack size
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    notifyListeners();
  }

  // Undo the last command
  Future<void> undo({Function(String)? onMessage}) async {
    if (!canUndo) return;

    final command = _undoStack.removeLast();
    await command.undo();

    // Add to redo stack
    _redoStack.add(command);

    // Limit redo stack size
    if (_redoStack.length > maxHistorySize) {
      _redoStack.removeAt(0);
    }

    // Show message if callback provided
    onMessage?.call('Undone: ${command.description}');

    notifyListeners();
  }

  // Redo the last undone command
  Future<void> redo({Function(String)? onMessage}) async {
    if (!canRedo) return;

    final command = _redoStack.removeLast();
    await command.execute();

    // Add back to undo stack
    _undoStack.add(command);

    // Limit undo stack size
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    // Show message if callback provided
    onMessage?.call('Redone: ${command.description}');

    notifyListeners();
  }

  // Clear both stacks
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  // Get undo history for UI display
  List<String> getUndoHistory() {
    return _undoStack.reversed.map((cmd) => cmd.description).toList();
  }

  // Get redo history for UI display
  List<String> getRedoHistory() {
    return _redoStack.reversed.map((cmd) => cmd.description).toList();
  }
}