import { invoke } from '@tauri-apps/api/core';

export interface Note {
  id: string;
  title: string;
  content: string;
  updated_at: string;
  version: number;
}

class NoteStore {
  // Svelte 5 Runes
  notes = $state<Note[]>([]);
  selectedId = $state<string | null>(null);

  // Derived state for the active note
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
      const newNote = await invoke<Note>('create_note', {
        title: 'Untitled Note',
        content: '',
      });
      this.notes = [newNote, ...this.notes];
      this.selectedId = newNote.id;
    } catch (e) {
      console.error('Failed to create note:', e);
    }
  }

  async save(id: string, title: string, content: string) {
    try {
      // Optimistic update
      const index = this.notes.findIndex((n) => n.id === id);
      if (index !== -1) {
        this.notes[index] = { ...this.notes[index], title, content };
      }

      // Persist
      const updated = await invoke<Note>('update_note', { id, title, content });

      // Confirm update from server (handles version bumps etc)
      if (index !== -1) {
        this.notes[index] = updated;
      }
    } catch (e) {
      console.error('Failed to save note:', e);
      await this.load(); // Revert on error
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
