import { create } from 'zustand';
import { Command } from '@/lib/models/command';

const MAX_HISTORY_SIZE = 50;

interface UndoRedoState {
  undoStack: Command[];
  redoStack: Command[];

  canUndo: boolean;
  canRedo: boolean;
  undoDescription: string | null;
  redoDescription: string | null;

  executeCommand: (command: Command) => Promise<void>;
  undo: (onMessage?: (msg: string) => void) => Promise<void>;
  redo: (onMessage?: (msg: string) => void) => Promise<void>;
  clearHistory: () => void;
}

export const useUndoRedoStore = create<UndoRedoState>((set, get) => ({
  undoStack: [],
  redoStack: [],

  get canUndo() {
    return get().undoStack.length > 0;
  },
  get canRedo() {
    return get().redoStack.length > 0;
  },
  get undoDescription() {
    const stack = get().undoStack;
    return stack.length > 0 ? stack[stack.length - 1].description : null;
  },
  get redoDescription() {
    const stack = get().redoStack;
    return stack.length > 0 ? stack[stack.length - 1].description : null;
  },

  executeCommand: async (command) => {
    await command.execute();
    const undoStack = [...get().undoStack, command];
    if (undoStack.length > MAX_HISTORY_SIZE) undoStack.shift();
    set({ undoStack, redoStack: [] });
  },

  undo: async (onMessage) => {
    const { undoStack } = get();
    if (undoStack.length === 0) return;

    const newUndo = [...undoStack];
    const command = newUndo.pop()!;
    await command.undo();

    const redoStack = [...get().redoStack, command];
    if (redoStack.length > MAX_HISTORY_SIZE) redoStack.shift();

    set({ undoStack: newUndo, redoStack });
    onMessage?.(`Undone: ${command.description}`);
  },

  redo: async (onMessage) => {
    const { redoStack } = get();
    if (redoStack.length === 0) return;

    const newRedo = [...redoStack];
    const command = newRedo.pop()!;
    await command.execute();

    const undoStack = [...get().undoStack, command];
    if (undoStack.length > MAX_HISTORY_SIZE) undoStack.shift();

    set({ undoStack, redoStack: newRedo });
    onMessage?.(`Redone: ${command.description}`);
  },

  clearHistory: () => set({ undoStack: [], redoStack: [] }),
}));
