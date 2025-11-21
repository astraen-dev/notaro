export interface HistoryState {
  title: string;
  content: string;
  cursorField: 'title' | 'content';
  cursorPos: number;
}

export class HistoryStore {
  // Private stacks
  private undoStack = $state<HistoryState[]>([]);
  private redoStack = $state<HistoryState[]>([]);

  // Derived status for UI
  canUndo = $derived(this.undoStack.length > 0);
  canRedo = $derived(this.redoStack.length > 0);

  constructor() {}

  /**
   * Clears history. Call this when switching notes.
   */
  clear() {
    this.undoStack = [];
    this.redoStack = [];
  }

  /**
   * Captures a snapshot of the current state into the undo stack.
   * Clears the redo stack because a new timeline has started.
   */
  snapshot(state: HistoryState) {
    // prevent duplicate snapshots if data hasn't actually changed
    const last = this.undoStack[this.undoStack.length - 1];
    if (last && last.title === state.title && last.content === state.content) {
      // Just update cursor pos if text is same
      last.cursorPos = state.cursorPos;
      last.cursorField = state.cursorField;
      return;
    }

    this.undoStack.push(state);
    this.redoStack = [];
  }

  /**
   * Performs Undo.
   * @param currentState The current state of the editor (to save into redo stack)
   * @returns The state to restore to, or null if stack is empty
   */
  undo(currentState: HistoryState): HistoryState | null {
    if (this.undoStack.length === 0) return null;

    const prevState = this.undoStack.pop();
    if (prevState) {
      this.redoStack.push(currentState);
      return prevState;
    }
    return null;
  }

  /**
   * Performs Redo.
   * @param currentState The current state of the editor (to save into undo stack)
   * @returns The state to restore to, or null if stack is empty
   */
  redo(currentState: HistoryState): HistoryState | null {
    if (this.redoStack.length === 0) return null;

    const nextState = this.redoStack.pop();
    if (nextState) {
      this.undoStack.push(currentState);
      return nextState;
    }
    return null;
  }
}

// Export a singleton or let components instantiate.
// Given we only have one active editor at a time, a singleton is fine,
// but instantiating in the component allows for multiple tabs in the future.
// We will export the class.
