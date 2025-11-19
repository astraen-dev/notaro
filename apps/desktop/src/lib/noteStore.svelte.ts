import { invoke } from '@tauri-apps/api/core';

export interface Note {
  id: string;
  title: string;
  content: string;
  updated_at: string;
  version: number;
}

export type SyncState = 'idle' | 'saving' | 'saved' | 'error';

class NoteStore {
  // Svelte 5 Runes
  notes = $state<Note[]>([]);
  selectedId = $state<string | null>(null);
  searchQuery = $state<string>('');
  syncState = $state<SyncState>('idle');

  // Derived: Filtered and Sorted (Instant Search)
  filteredNotes = $derived.by(() => {
    const query = this.searchQuery.toLowerCase();
    return this.notes
      .filter(
        (n) =>
          n.title.toLowerCase().includes(query) ||
          n.content.toLowerCase().includes(query)
      )
      .sort(
        (a, b) =>
          new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
      );
  });

  // Derived: Active Note
  selectedNote = $derived(
    this.notes.find((n) => n.id === this.selectedId) || null
  );

  constructor() {
    this.load();
  }

  async load() {
    try {
      this.notes = await invoke('get_notes');
    } catch (e) {
      console.error('Failed to load notes:', e);
    }
  }

  select(id: string) {
    this.selectedId = id;
  }

  async add() {
    try {
      this.syncState = 'saving';
      const newNote = await invoke<Note>('create_note', {
        title: '',
        content: '',
      });
      this.notes = [newNote, ...this.notes];
      this.selectedId = newNote.id;
      this.searchQuery = ''; // Clear search to show new note
      this.syncState = 'saved';
      setTimeout(() => (this.syncState = 'idle'), 2000);
    } catch (e) {
      console.error('Failed to create note:', e);
      this.syncState = 'error';
    }
  }

  async save(id: string, title: string, content: string) {
    try {
      this.syncState = 'saving';

      // Optimistic update
      const index = this.notes.findIndex((n) => n.id === id);
      if (index !== -1) {
        this.notes[index] = {
          ...this.notes[index],
          title,
          content,
          updated_at: new Date().toISOString(), // Update time locally for sort
        };
      }

      // Persist to Rust Core
      const updated = await invoke<Note>('update_note', { id, title, content });

      // Reconcile
      const reIndex = this.notes.findIndex((n) => n.id === id);
      if (reIndex !== -1) {
        this.notes[reIndex] = updated;
      }

      this.syncState = 'saved';
      setTimeout(() => (this.syncState = 'idle'), 2000);
    } catch (e) {
      console.error('Failed to save note:', e);
      this.syncState = 'error';
      await this.load(); // Revert
    }
  }

  async delete(id: string) {
    try {
      await invoke('delete_note', { id });
      this.notes = this.notes.filter((n) => n.id !== id);
      if (this.selectedId === id) {
        this.selectedId = null;
      }
    } catch (e) {
      console.error('Failed to delete note:', e);
    }
  }
}

export const noteStore = new NoteStore();
