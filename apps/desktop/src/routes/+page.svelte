<script lang="ts">
  import { noteStore } from '$lib/noteStore.svelte';
  import { settingsStore } from '$lib/settingsStore.svelte';
  import SettingsModal from '../components/SettingsModal.svelte';
  import { fade } from 'svelte/transition';
  import { onMount } from 'svelte';
  import {
    Plus,
    Trash2,
    Search,
    FileText,
    PenLine,
    CheckCircle2,
    Cloud,
    Loader2,
    Settings,
  } from '@lucide/svelte';
  import '../app.css';

  let timer: ReturnType<typeof setTimeout>;

  // Initialize stores on mount (ensures Tauri/DOM are ready)
  onMount(() => {
    void noteStore.init();
    void settingsStore.init();
  });

  // Reactive Effect: Apply Settings to DOM
  // This must be in a component (not the global store class) to link to the lifecycle
  $effect(() => {
    const root = document.documentElement;
    const s = settingsStore.settings;

    // 1. Apply Font
    const fonts = {
      sans: '"Inter", sans-serif',
      serif: '"Merriweather", serif',
      mono: '"JetBrains Mono", monospace',
    };
    root.style.setProperty('--font-main', fonts[s.font_family]);
    root.style.setProperty('--font-size-base', `${s.font_size}px`);

    // 2. Apply Accent Hue (HSL)
    root.style.setProperty('--accent-hue', s.accent_hue.toString());

    // 3. Apply Theme
    const isDark =
      s.theme_mode === 'dark' ||
      (s.theme_mode === 'system' &&
        window.matchMedia('(prefers-color-scheme: dark)').matches);

    if (isDark) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  });

  // Date formatter for the list
  const formatDate = (iso: string) => {
    const date = new Date(iso);
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
    }).format(date);
  };

  function handleInput(e: Event, field: 'title' | 'content') {
    if (!noteStore.selectedNote) return;

    const val = (e.target as HTMLInputElement | HTMLTextAreaElement).value;
    const title = field === 'title' ? val : noteStore.selectedNote.title;
    const content = field === 'content' ? val : noteStore.selectedNote.content;

    // Immediate update happens in store via optimistic UI
    // We just debounce the actual invoke call
    clearTimeout(timer);
    timer = setTimeout(() => {
      if (noteStore.selectedNote) {
        noteStore.save(noteStore.selectedNote.id, title, content);
      }
    }, 400);
  }
</script>

<SettingsModal />

<main
  class="flex h-screen w-screen gap-3 overflow-hidden p-3 text-slate-700 selection:bg-indigo-100 selection:text-indigo-900"
>
  <!-- GLASS SIDEBAR -->
  <aside
    class="flex w-72 flex-col overflow-hidden rounded-2xl border border-white/50 bg-white/40 shadow-xl backdrop-blur-xl transition-all"
  >
    <!-- Sidebar Header (Draggable) -->
    <div
      data-tauri-drag-region
      class="flex items-center justify-between p-4 pb-2 select-none"
    >
      <div class="flex items-center gap-2 text-indigo-900/80">
        <Cloud size={18} strokeWidth={2.5} />
        <span class="text-lg font-bold tracking-tight">Notaro</span>
      </div>

      <div class="flex items-center gap-1">
        <button
          onclick={() => settingsStore.toggle()}
          class="rounded-lg border border-transparent p-1.5 text-slate-500 transition-all hover:bg-white/50 hover:text-slate-700 active:scale-95 dark:text-slate-400 dark:hover:text-slate-200"
          title="Settings"
        >
          <Settings size={18} />
        </button>

        <button
          onclick={() => noteStore.add()}
          class="rounded-lg border border-white/40 bg-white/50 p-1.5 text-indigo-600 shadow-sm transition-all hover:bg-white/80 hover:text-indigo-700 active:scale-95"
          title="New Note"
        >
          <Plus size={20} />
        </button>
      </div>
    </div>

    <!-- Search Bar -->
    <div class="px-4 py-2">
      <div class="group relative">
        <Search
          class="absolute top-1/2 left-3 -translate-y-1/2 text-slate-400 transition-colors group-focus-within:text-indigo-500"
          size={16}
        />
        <input
          type="text"
          bind:value={noteStore.searchQuery}
          placeholder="Search notes..."
          class="w-full rounded-xl border border-transparent bg-slate-50/50 py-2 pr-3 pl-9 text-sm transition-all outline-none placeholder:text-slate-400 focus:border-indigo-200/50 focus:bg-white/70"
        />
      </div>
    </div>

    <!-- Note List -->
    <div class="custom-scrollbar flex-1 space-y-1 overflow-y-auto p-2">
      {#each noteStore.filteredNotes as note (note.id)}
        <button
          onclick={() => noteStore.select(note.id)}
          class="group relative w-full overflow-hidden rounded-xl border border-transparent p-3 text-left transition-all duration-200
          {noteStore.selectedId === note.id
            ? 'border-white/60 bg-white/80 shadow-sm'
            : 'hover:border-white/20 hover:bg-white/30'}"
        >
          <span class="mb-1 flex w-full items-start justify-between">
            <span
              class="truncate pr-2 font-semibold {noteStore.selectedId ===
              note.id
                ? 'text-slate-800'
                : 'text-slate-600'}"
            >
              {note.title || 'Untitled Note'}
            </span>
            <span
              class="mt-1 text-[10px] font-medium whitespace-nowrap opacity-50"
            >
              {formatDate(note.updated_at)}
            </span>
          </span>

          <span class="block h-4 truncate text-xs opacity-60">
            {note.content || 'No additional text'}
          </span>
        </button>
      {/each}

      {#if noteStore.filteredNotes.length === 0}
        <div
          class="flex h-40 flex-col items-center justify-center space-y-2 text-slate-400"
          in:fade
        >
          <FileText size={32} class="opacity-20" />
          <span class="text-sm">No notes found</span>
        </div>
      {/if}
    </div>
  </aside>

  <!-- MAIN EDITOR -->
  <section
    class="relative flex flex-1 flex-col overflow-hidden rounded-2xl border border-white/60 bg-white/60 shadow-2xl backdrop-blur-2xl"
  >
    {#if noteStore.selectedNote}
      <!-- Toolbar / Header (Draggable) -->
      <header
        data-tauri-drag-region
        class="flex h-14 items-center justify-between border-b border-slate-200/30 bg-white/10 px-6"
      >
        <div class="flex items-center gap-2 font-mono text-xs text-slate-400">
          {#if noteStore.syncState === 'saving'}
            <Loader2 size={12} class="animate-spin" />
            Saving...
          {:else if noteStore.syncState === 'saved'}
            <CheckCircle2 size={12} class="text-emerald-500" />
            Saved
          {:else if noteStore.syncState === 'error'}
            <span class="text-red-400">Sync Error</span>
          {:else}
            <span class="opacity-0 transition-opacity hover:opacity-100"
              >v{noteStore.selectedNote.version}</span
            >
          {/if}
        </div>

        <div class="flex items-center gap-2">
          <button
            onclick={() =>
              noteStore.selectedNote &&
              noteStore.delete(noteStore.selectedNote.id)}
            class="rounded-lg p-2 text-slate-400 transition-all hover:bg-red-50 hover:text-red-500"
            title="Delete Note"
          >
            <Trash2 size={18} />
          </button>
        </div>
      </header>

      <!-- Input Area -->
      <div
        class="mx-auto flex w-full max-w-3xl flex-1 flex-col overflow-hidden"
        in:fade={{ duration: 150 }}
      >
        <!-- Title -->
        <input
          type="text"
          value={noteStore.selectedNote.title}
          oninput={(e) => handleInput(e, 'title')}
          class="w-full bg-transparent px-8 pt-8 pb-4 text-3xl font-bold text-slate-800 outline-none placeholder:text-slate-300"
          placeholder="Untitled Note"
        />

        <!-- Content -->
        <textarea
          oninput={(e) => handleInput(e, 'content')}
          class="custom-scrollbar w-full flex-1 resize-none bg-transparent px-8 py-2 text-lg leading-relaxed text-slate-600 outline-none placeholder:text-slate-300"
          placeholder="Start typing your thoughts..."
          spellcheck="false">{noteStore.selectedNote.content}</textarea
        >
      </div>
    {:else}
      <!-- Empty State -->
      <div
        class="flex flex-1 flex-col items-center justify-center space-y-4 text-slate-400"
      >
        <div class="rounded-full bg-white/30 p-4 shadow-sm">
          <PenLine size={48} class="text-indigo-300 opacity-30" />
        </div>
        <p class="text-sm font-medium opacity-60">
          Select a note or create a new one
        </p>
      </div>
    {/if}
  </section>
</main>
