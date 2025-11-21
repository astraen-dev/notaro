import { invoke } from '@tauri-apps/api/core';

export interface Note {
  id: string;
  title: string;
  content: string;
  updated_at: string;
  version: number;
  folder: string | null;
  is_pinned: boolean;
}

export type SyncState = 'idle' | 'saving' | 'saved' | 'error';

class NoteStore {
  // Svelte 5 Runes
  notes = $state<Note[]>([]);
  selectedId = $state<string | null>(null);
  searchQuery = $state<string>('');

  // Navigation State
  selectedFolder = $state<string | 'all' | 'pinned'>('all');
  syncState = $state<SyncState>('idle');

  // Derived: Unique Folders List
  availableFolders = $derived.by(() => {
    const folders: Record<string, boolean> = {};
    this.notes.forEach((n) => {
      if (n.folder && n.folder.trim() !== '') {
        folders[n.folder] = true;
      }
    });
    return Object.keys(folders).sort();
  });

  // Derived: Filtered and Sorted (Search + Navigation + Sort)
  filteredNotes = $derived.by(() => {
    const query = this.searchQuery.toLowerCase();

    // 1. Filter
    const filtered = this.notes.filter((n) => {
      // Search Text
      const matchesSearch =
        n.title.toLowerCase().includes(query) ||
        n.content.toLowerCase().includes(query);

      if (!matchesSearch) return false;

      // Navigation Context
      if (this.selectedFolder === 'all') return true;
      if (this.selectedFolder === 'pinned') return n.is_pinned;
      return n.folder === this.selectedFolder;
    });

    // 2. Sort: Pinned first, then updated date
    return filtered.sort((a, b) => {
      // If one is pinned and the other isn't, pinned comes first
      if (a.is_pinned !== b.is_pinned) return a.is_pinned ? -1 : 1;

      // Otherwise sort by recency
      return (
        new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
      );
    });
  });

  // Derived: Active Note
  selectedNote = $derived(
    this.notes.find((n) => n.id === this.selectedId) || null
  );

  constructor() {}

  async init() {
    try {
      this.notes = await invoke('get_notes');
    } catch (e) {
      console.error('Failed to load notes:', e);
    }
  }

  select(id: string) {
    this.selectedId = id;
  }

  selectFolder(folder: string | 'all' | 'pinned') {
    this.selectedFolder = folder;
    this.selectedId = null; // Deselect note when changing context
  }

  async add() {
    try {
      this.syncState = 'saving';

      // Inherit current folder if specific one is selected (not All/Pinned)
      const folderToUse =
        this.selectedFolder !== 'all' && this.selectedFolder !== 'pinned'
          ? this.selectedFolder
          : null;

      const newNote = await invoke<Note>('create_note', {
        title: '',
        content: '',
        folder: folderToUse,
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

  async save(
    id: string,
    title: string,
    content: string,
    folder: string | null,
    isPinned: boolean
  ) {
    try {
      this.syncState = 'saving';

      // Optimistic update
      const index = this.notes.findIndex((n) => n.id === id);
      if (index !== -1) {
        this.notes[index] = {
          ...this.notes[index],
          title,
          content,
          folder,
          is_pinned: isPinned,
          updated_at: new Date().toISOString(), // Update time locally for sort
        };
      }

      // Persist to Rust Core
      const updated = await invoke<Note>('update_note', {
        id,
        title,
        content,
        folder,
        isPinned,
      });

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
      await this.init(); // Revert on error
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
