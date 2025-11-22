import { invoke } from '@tauri-apps/api/core';

export interface Note {
  id: string;
  title: string;
  content: string;
  updated_at: string;
  version: number;
  folder: string | null;
  is_pinned: boolean;
  is_deleted: boolean;
}

export type SyncState = 'idle' | 'saving' | 'saved' | 'error';

class NoteStore {
  notes = $state<Note[]>([]);
  selectedId = $state<string | null>(null);
  searchQuery = $state<string>('');

  // Navigation State
  selectedFolder = $state<string | 'all' | 'pinned' | 'trash'>('all');
  syncState = $state<SyncState>('idle');

  // Derived: Unique Folders List
  availableFolders = $derived.by(() => {
    const folders: Record<string, boolean> = {};
    this.notes.forEach((n) => {
      // Only show folders from active notes
      if (!n.is_deleted && n.folder && n.folder.trim() !== '') {
        folders[n.folder] = true;
      }
    });
    return Object.keys(folders).sort();
  });

  // Derived: Filtered and Sorted
  filteredNotes = $derived.by(() => {
    const query = this.searchQuery.toLowerCase();

    const filtered = this.notes.filter((n) => {
      // 1. Handle Trash Context explicitly
      if (this.selectedFolder === 'trash') {
        // In trash mode, ONLY show deleted notes
        if (!n.is_deleted) return false;
      } else {
        // In normal modes, ONLY show active notes
        if (n.is_deleted) return false;
      }

      // 2. Search Text
      const matchesSearch =
        n.title.toLowerCase().includes(query) ||
        n.content.toLowerCase().includes(query);

      if (!matchesSearch) return false;

      // 3. Navigation Context
      if (this.selectedFolder === 'trash') return true; // Already filtered by is_deleted
      if (this.selectedFolder === 'all') return true;
      if (this.selectedFolder === 'pinned') return n.is_pinned;
      return n.folder === this.selectedFolder;
    });

    // Sort: Pinned first, then updated date
    return filtered.sort((a, b) => {
      if (a.is_pinned !== b.is_pinned) return a.is_pinned ? -1 : 1;
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
    // Prevent creating notes while in Trash
    if (this.selectedFolder === 'trash') return;

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

      const index = this.notes.findIndex((n) => n.id === id);
      if (index === -1) return;

      const note = this.notes[index];

      if (note.is_deleted) {
        // Case 2: Hard Delete (Already in trash) -> Remove from store
        this.notes = this.notes.filter((n) => n.id !== id);
        if (this.selectedId === id) this.selectedId = null;
      } else {
        // Case 1: Soft Delete -> Mark as deleted in store
        this.notes[index] = { ...note, is_deleted: true };
        // If we are not in trash view, this note disappears, so deselect
        if (this.selectedFolder !== 'trash' && this.selectedId === id) {
          this.selectedId = null;
        }
      }
    } catch (e) {
      console.error('Failed to delete note:', e);
    }
  }

  async restore(id: string) {
    try {
      await invoke('restore_note', { id });

      const index = this.notes.findIndex((n) => n.id === id);
      if (index !== -1) {
        // Mark as active
        this.notes[index] = { ...this.notes[index], is_deleted: false };
        // Note disappears from Trash view
        if (this.selectedFolder === 'trash' && this.selectedId === id) {
          this.selectedId = null;
        }
      }
    } catch (e) {
      console.error('Failed to restore note:', e);
    }
  }
}

export const noteStore = new NoteStore();
