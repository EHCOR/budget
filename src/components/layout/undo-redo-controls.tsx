'use client';

import { Undo2, Redo2 } from 'lucide-react';
import { useUndoRedoStore } from '@/lib/stores/undo-redo-store';
import { useToast } from '@/components/shared/toast';
import { cn } from '@/lib/utils/cn';

export function UndoRedoControls() {
  const { undoStack, redoStack, undo, redo } = useUndoRedoStore();
  const { showToast } = useToast();

  const canUndo = undoStack.length > 0;
  const canRedo = redoStack.length > 0;
  const undoDesc = canUndo ? undoStack[undoStack.length - 1].description : null;
  const redoDesc = canRedo ? redoStack[redoStack.length - 1].description : null;

  return (
    <div className="flex items-center gap-1">
      <button
        onClick={() => undo(showToast)}
        disabled={!canUndo}
        title={undoDesc ? `Undo: ${undoDesc}` : 'Nothing to undo'}
        className={cn(
          'rounded-lg p-2 transition-colors',
          canUndo
            ? 'text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700'
            : 'text-gray-300 dark:text-gray-600'
        )}
      >
        <Undo2 size={20} />
      </button>
      <button
        onClick={() => redo(showToast)}
        disabled={!canRedo}
        title={redoDesc ? `Redo: ${redoDesc}` : 'Nothing to redo'}
        className={cn(
          'rounded-lg p-2 transition-colors',
          canRedo
            ? 'text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700'
            : 'text-gray-300 dark:text-gray-600'
        )}
      >
        <Redo2 size={20} />
      </button>
    </div>
  );
}
