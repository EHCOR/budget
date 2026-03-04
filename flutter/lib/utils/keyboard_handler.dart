// utils/keyboard_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/undo_redo_provider.dart';

class KeyboardHandler extends StatelessWidget {
  final Widget child;

  const KeyboardHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          final undoRedoProvider = Provider.of<UndoRedoProvider>(context, listen: false);
          undoRedoProvider.undo(
            onMessage: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          final undoRedoProvider = Provider.of<UndoRedoProvider>(context, listen: false);
          undoRedoProvider.redo(
            onMessage: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
          final undoRedoProvider = Provider.of<UndoRedoProvider>(context, listen: false);
          undoRedoProvider.redo(
            onMessage: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}