// widgets/undo_redo_controls.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/undo_redo_provider.dart';

class UndoRedoControls extends StatelessWidget {
  const UndoRedoControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UndoRedoProvider>(
      builder: (context, undoRedoProvider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: undoRedoProvider.canUndo
                  ? () => undoRedoProvider.undo(
                      onMessage: (message) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    )
                  : null,
              icon: const Icon(Icons.undo),
              tooltip: undoRedoProvider.canUndo
                  ? 'Undo: ${undoRedoProvider.undoDescription}'
                  : 'Nothing to undo',
            ),
            IconButton(
              onPressed: undoRedoProvider.canRedo
                  ? () => undoRedoProvider.redo(
                      onMessage: (message) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    )
                  : null,
              icon: const Icon(Icons.redo),
              tooltip: undoRedoProvider.canRedo
                  ? 'Redo: ${undoRedoProvider.redoDescription}'
                  : 'Nothing to redo',
            ),
          ],
        );
      },
    );
  }
}