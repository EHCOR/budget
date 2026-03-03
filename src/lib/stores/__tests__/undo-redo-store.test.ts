import { describe, it, expect, beforeEach } from 'vitest';
import { useUndoRedoStore } from '../undo-redo-store';
import type { Command } from '@/lib/models/command';

function createMockCommand(desc: string): Command & { executed: boolean; undone: boolean } {
  const cmd = {
    description: desc,
    executed: false,
    undone: false,
    async execute() {
      cmd.executed = true;
      cmd.undone = false;
    },
    async undo() {
      cmd.undone = true;
      cmd.executed = false;
    },
  };
  return cmd;
}

describe('useUndoRedoStore', () => {
  beforeEach(() => {
    useUndoRedoStore.getState().clearHistory();
  });

  it('executes a command and pushes to undo stack', async () => {
    const cmd = createMockCommand('test');
    await useUndoRedoStore.getState().executeCommand(cmd);

    expect(cmd.executed).toBe(true);
    expect(useUndoRedoStore.getState().undoStack).toHaveLength(1);
    expect(useUndoRedoStore.getState().redoStack).toHaveLength(0);
  });

  it('undoes a command', async () => {
    const cmd = createMockCommand('test undo');
    await useUndoRedoStore.getState().executeCommand(cmd);
    await useUndoRedoStore.getState().undo();

    expect(cmd.undone).toBe(true);
    expect(useUndoRedoStore.getState().undoStack).toHaveLength(0);
    expect(useUndoRedoStore.getState().redoStack).toHaveLength(1);
  });

  it('redoes a command', async () => {
    const cmd = createMockCommand('test redo');
    await useUndoRedoStore.getState().executeCommand(cmd);
    await useUndoRedoStore.getState().undo();
    await useUndoRedoStore.getState().redo();

    expect(cmd.executed).toBe(true);
    expect(useUndoRedoStore.getState().undoStack).toHaveLength(1);
    expect(useUndoRedoStore.getState().redoStack).toHaveLength(0);
  });

  it('clears redo stack on new command', async () => {
    const cmd1 = createMockCommand('first');
    const cmd2 = createMockCommand('second');

    await useUndoRedoStore.getState().executeCommand(cmd1);
    await useUndoRedoStore.getState().undo();
    expect(useUndoRedoStore.getState().redoStack).toHaveLength(1);

    await useUndoRedoStore.getState().executeCommand(cmd2);
    expect(useUndoRedoStore.getState().redoStack).toHaveLength(0);
  });

  it('limits stack size to 50', async () => {
    for (let i = 0; i < 55; i++) {
      await useUndoRedoStore.getState().executeCommand(createMockCommand(`cmd-${i}`));
    }
    expect(useUndoRedoStore.getState().undoStack.length).toBeLessThanOrEqual(50);
  });

  it('does nothing on undo with empty stack', async () => {
    await useUndoRedoStore.getState().undo();
    expect(useUndoRedoStore.getState().undoStack).toHaveLength(0);
  });

  it('calls onMessage callback', async () => {
    const cmd = createMockCommand('callback test');
    await useUndoRedoStore.getState().executeCommand(cmd);

    let message = '';
    await useUndoRedoStore.getState().undo((msg) => { message = msg; });
    expect(message).toBe('Undone: callback test');
  });

  it('clears history', async () => {
    await useUndoRedoStore.getState().executeCommand(createMockCommand('a'));
    await useUndoRedoStore.getState().executeCommand(createMockCommand('b'));
    useUndoRedoStore.getState().clearHistory();

    expect(useUndoRedoStore.getState().undoStack).toHaveLength(0);
    expect(useUndoRedoStore.getState().redoStack).toHaveLength(0);
  });
});
