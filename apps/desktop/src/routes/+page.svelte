<script lang="ts">
  import { noteStore } from '$lib/noteStore.svelte';
  import { settingsStore } from '$lib/settingsStore.svelte';
  import { HistoryStore, type HistoryState } from '$lib/historyStore.svelte';
  import SettingsModal from '../components/SettingsModal.svelte';
  import { fade, slide } from 'svelte/transition';
  import { onMount, tick, onDestroy } from 'svelte';
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
    PanelLeft,
    Copy,
    Check,
    Type,
    Undo2,
    Redo2,
    Pin,
    Folder,
    FolderOpen,
    Trash,
    RotateCcw,
    MoreVertical,
    X,
  } from '@lucide/svelte';
  import '../app.css';

  let timer: ReturnType<typeof setTimeout>;

  let isSidebarOpen = $state(true);
  let isCopied = $state(false);
  let isMobileMenuOpen = $state(false);

  let editorSectionRef = $state<HTMLElement>();
  let editorWidth = $state(1000);
  let resizeObserver: ResizeObserver;

  let localTitle = $state('');
  let localContent = $state('');
  let localFolder = $state<string | null>(null);
  let localPinned = $state(false);

  let currentNoteId = $state<string | null>(null);

  let titleRef = $state<HTMLInputElement>();
  let contentRef = $state<HTMLTextAreaElement>();

  const history = new HistoryStore();
  let lastInputTime = 0;
  const HISTORY_DEBOUNCE = 1000;

  // UI Constants for Dynamic Calculation
  const UI_METRICS = {
    PADDING: 32, // px-4 * 2
    GAP_L: 16, // gap-4
    GAP_S: 4, // gap-1 / gap-2
    BTN: 40, // Standard button touch target
    FOLDER: 140, // Folder input width + icon
    COPY: 70, // Copy button with text
    RESTORE: 90, // Restore button with text
    MENU: 40, // Hamburger menu
  };

  onMount(() => {
    void noteStore.init();
    void settingsStore.init();

    if (editorSectionRef) {
      resizeObserver = new ResizeObserver((entries) => {
        for (const entry of entries) {
          editorWidth = entry.contentRect.width;
        }
      });
      resizeObserver.observe(editorSectionRef);
    }
  });

  onDestroy(() => {
    if (resizeObserver) resizeObserver.disconnect();
  });

  $effect(() => {
    if (noteStore.selectedId !== currentNoteId) {
      currentNoteId = noteStore.selectedId;
      if (noteStore.selectedNote) {
        localTitle = noteStore.selectedNote.title;
        localContent = noteStore.selectedNote.content;
        localFolder = noteStore.selectedNote.folder;
        localPinned = noteStore.selectedNote.is_pinned;
      } else {
        localTitle = '';
        localContent = '';
        localFolder = null;
        localPinned = false;
      }

      history.clear();
      lastInputTime = 0;
      isMobileMenuOpen = false;
    }
  });

  $effect(() => {
    const root = document.documentElement;
    const s = settingsStore.settings;

    const fonts = {
      sans: '"Inter", sans-serif',
      serif: '"Merriweather", serif',
      mono: '"JetBrains Mono", monospace',
    };
    root.style.setProperty('--font-main', fonts[s.font_family] || fonts.sans);
    root.style.setProperty('--font-size-base', `${s.font_size}px`);
    root.style.setProperty('--accent-hue', s.accent_hue.toString());

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

  const formatDate = (iso: string) => {
    const date = new Date(iso);
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
    }).format(date);
  };

  function getCurrentCursorState(): {
    field: 'title' | 'content';
    pos: number;
  } {
    const field = document.activeElement === titleRef ? 'title' : 'content';
    const pos =
      (field === 'title'
        ? titleRef?.selectionStart
        : contentRef?.selectionStart) || 0;
    return { field, pos };
  }

  async function applyHistoryState(state: HistoryState) {
    localTitle = state.title;
    localContent = state.content;
    saveProperties();
    await tick();
    if (state.cursorField === 'title' && titleRef) {
      titleRef.focus();
      const pos = Math.min(state.cursorPos, localTitle.length);
      titleRef.setSelectionRange(pos, pos);
    } else if (state.cursorField === 'content' && contentRef) {
      contentRef.focus();
      const pos = Math.min(state.cursorPos, localContent.length);
      contentRef.setSelectionRange(pos, pos);
    }
  }

  function saveProperties() {
    if (!noteStore.selectedNote) return;
    noteStore.save(
      noteStore.selectedNote.id,
      localTitle,
      localContent,
      localFolder,
      localPinned
    );
  }

  function togglePin() {
    localPinned = !localPinned;
    saveProperties();
  }

  function updateFolder(e: Event) {
    const val = (e.target as HTMLInputElement).value.trim();
    localFolder = val === '' ? null : val;
    saveProperties();
  }

  function performUndo() {
    if (!history.canUndo) return;

    const { field, pos } = getCurrentCursorState();
    const currentState: HistoryState = {
      title: localTitle,
      content: localContent,
      cursorField: field,
      cursorPos: pos,
    };

    const prevState = history.undo(currentState);
    if (prevState) applyHistoryState(prevState);
  }

  function performRedo() {
    if (!history.canRedo) return;

    const { field, pos } = getCurrentCursorState();
    const currentState: HistoryState = {
      title: localTitle,
      content: localContent,
      cursorField: field,
      cursorPos: pos,
    };

    const nextState = history.redo(currentState);
    if (nextState) applyHistoryState(nextState);
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.metaKey || e.ctrlKey) {
      if (e.key === 'z') {
        e.preventDefault();
        if (e.shiftKey) {
          performRedo();
        } else {
          performUndo();
        }
      } else if (e.key === 'y') {
        e.preventDefault();
        performRedo();
      }
    }
  }

  function handleInput(e: Event, field: 'title' | 'content') {
    const target = e.target as HTMLInputElement | HTMLTextAreaElement;
    const val = target.value;
    const now = Date.now();

    if (now - lastInputTime > HISTORY_DEBOUNCE) {
      history.snapshot({
        title: localTitle,
        content: localContent,
        cursorField: field,
        cursorPos: field === 'title' ? localTitle.length : localContent.length,
      });
    }
    lastInputTime = now;

    if (field === 'title') localTitle = val;
    if (field === 'content') localContent = val;

    clearTimeout(timer);
    timer = setTimeout(() => {
      saveProperties();
    }, 400);
  }

  function toggleSidebar() {
    isSidebarOpen = !isSidebarOpen;
  }

  function selectNote(id: string) {
    noteStore.select(id);
    if (window.innerWidth < 768) {
      isSidebarOpen = false;
    }
  }

  async function copyToClipboard() {
    try {
      await navigator.clipboard.writeText(localContent);
      isCopied = true;
      setTimeout(() => (isCopied = false), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  }

  let wordCount = $derived(
    localContent
      .trim()
      .split(/\s+/)
      .filter((w) => w.length > 0).length || 0
  );
  let charCount = $derived(localContent.length || 0);

  let isCompactToolbar = $derived.by(() => {
    if (!noteStore.selectedNote) return false;

    const isDeleted = noteStore.selectedNote.is_deleted;

    let requiredWidth = UI_METRICS.PADDING + UI_METRICS.BTN + UI_METRICS.GAP_L; // Toggle btn + padding

    if (isDeleted) {
      // Trash mode: Restore btn + Delete btn
      requiredWidth += UI_METRICS.RESTORE + UI_METRICS.GAP_S + UI_METRICS.BTN;
    } else {
      // Active mode: Pin + Folder + (Gap) + Undo + Redo + Copy + Delete
      const leftGroup = UI_METRICS.BTN + UI_METRICS.GAP_S + UI_METRICS.FOLDER;
      const rightGroup =
        UI_METRICS.BTN * 3 + UI_METRICS.COPY + UI_METRICS.GAP_S * 4;
      requiredWidth += leftGroup + UI_METRICS.GAP_L + rightGroup;
    }

    return editorWidth < requiredWidth;
  });
</script>

<svelte:window onkeydown={handleKeydown} />

<SettingsModal />

<main
  class="flex h-screen w-screen overflow-hidden bg-gradient-to-br from-transparent to-black/5 p-3 text-slate-700 selection:bg-indigo-100 selection:text-indigo-900"
>
  {#if isSidebarOpen}
    <div
      class="fixed inset-0 z-30 bg-black/20 backdrop-blur-[2px] md:hidden"
      onclick={() => (isSidebarOpen = false)}
      transition:fade={{ duration: 200 }}
      role="presentation"
    ></div>
  {/if}

  <aside
    class="fixed inset-y-3 left-3 z-40 flex h-[calc(100vh-1.5rem)] flex-col overflow-hidden rounded-2xl border border-white/50 bg-white/90 shadow-2xl backdrop-blur-xl transition-all duration-300 ease-[cubic-bezier(0.2,0,0,1)] md:relative md:inset-auto
    md:h-auto md:bg-white/40 md:shadow-xl
    {isSidebarOpen
      ? 'w-72 translate-x-0 opacity-100 md:mr-3'
      : 'w-0 -translate-x-4 border-0 opacity-0 md:mr-0'}"
  >
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

    <div class="flex gap-1 px-4 pb-2">
      <button
        onclick={() => noteStore.selectFolder('all')}
        class="flex-1 rounded-lg border border-transparent py-1 text-xs font-medium transition-colors
            {noteStore.selectedFolder === 'all'
          ? 'bg-indigo-100/50 text-indigo-700 shadow-sm'
          : 'text-slate-500 hover:bg-white/50'}"
      >
        All
      </button>
      <button
        onclick={() => noteStore.selectFolder('pinned')}
        class="flex flex-1 items-center justify-center gap-1 rounded-lg border border-transparent py-1 text-xs font-medium transition-colors
            {noteStore.selectedFolder === 'pinned'
          ? 'bg-indigo-100/50 text-indigo-700 shadow-sm'
          : 'text-slate-500 hover:bg-white/50'}"
      >
        <Pin
          size={10}
          class={noteStore.selectedFolder === 'pinned' ? 'fill-current' : ''}
        /> Pinned
      </button>
      <button
        onclick={() => noteStore.selectFolder('trash')}
        class="flex flex-1 items-center justify-center gap-1 rounded-lg border border-transparent py-1 text-xs font-medium transition-colors
            {noteStore.selectedFolder === 'trash'
          ? 'bg-red-100/50 text-red-700 shadow-sm'
          : 'text-slate-500 hover:bg-white/50'}"
      >
        <Trash size={10} /> Trash
      </button>
    </div>

    {#if noteStore.availableFolders.length > 0}
      <div class="mb-1 px-4 py-1">
        <div
          class="mb-1.5 text-[10px] font-bold tracking-wider text-slate-400 uppercase"
        >
          Folders
        </div>
        <div class="flex flex-wrap gap-1.5">
          {#each noteStore.availableFolders as folder (folder)}
            <button
              onclick={() => noteStore.selectFolder(folder)}
              class="flex items-center gap-1 rounded-md border px-2 py-1 text-[11px] transition-all
                    {noteStore.selectedFolder === folder
                ? 'border-indigo-200 bg-white text-indigo-600 shadow-sm'
                : 'border-transparent bg-white/30 text-slate-600 hover:bg-white/50'}"
            >
              <Folder size={10} />
              {folder}
            </button>
          {/each}
        </div>
      </div>
    {/if}

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

    <div class="custom-scrollbar flex-1 space-y-1 overflow-y-auto p-2">
      {#each noteStore.filteredNotes as note (note.id)}
        <button
          onclick={() => selectNote(note.id)}
          class="group relative w-full overflow-hidden rounded-xl border border-transparent p-3 text-left transition-all duration-200
          {noteStore.selectedId === note.id
            ? 'border-white/60 bg-white/80 shadow-sm'
            : 'hover:border-white/20 hover:bg-white/30'}"
        >
          <span class="mb-1 flex w-full items-start justify-between">
            <span
              class="flex items-center gap-1.5 truncate pr-2 font-semibold {noteStore.selectedId ===
              note.id
                ? 'text-slate-800'
                : 'text-slate-600'}"
            >
              {#if note.is_pinned}
                <Pin size={11} class="fill-current opacity-70" />
              {/if}
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

  <section
    bind:this={editorSectionRef}
    class="relative flex w-full flex-1 flex-col overflow-hidden rounded-2xl border border-white/60 bg-white/60 shadow-2xl backdrop-blur-2xl transition-all duration-300"
  >
    {#if noteStore.selectedNote}
      {#if noteStore.selectedNote.is_deleted}
        <div
          class="flex w-full items-center justify-center gap-2 bg-red-50/80 px-4 py-2 text-xs font-medium text-red-600 dark:bg-red-900/20 dark:text-red-400"
        >
          <Trash size={14} />
          <span>This note is in the trash. Editing is disabled.</span>
        </div>
      {/if}

      <header
        data-tauri-drag-region
        class="flex h-14 min-h-[3.5rem] items-center justify-between gap-4 border-b border-slate-200/30 bg-white/10 px-4"
      >
        <div class="flex items-center gap-4">
          <button
            onclick={toggleSidebar}
            class="rounded-lg p-2 text-slate-400 transition-all hover:bg-white/50 hover:text-slate-600 {isSidebarOpen
              ? 'opacity-50'
              : 'text-indigo-500 opacity-100'}"
            title={isSidebarOpen ? 'Collapse Sidebar' : 'Expand Sidebar'}
          >
            <PanelLeft size={18} />
          </button>

          {#if !noteStore.selectedNote.is_deleted}
            {#if !isCompactToolbar}
              <div class="flex items-center gap-2">
                <button
                  onclick={togglePin}
                  class="rounded-lg p-1.5 transition-all hover:bg-white/50 active:scale-90
                      {localPinned
                    ? 'text-indigo-500'
                    : 'text-slate-400 hover:text-slate-600'}"
                  title={localPinned ? 'Unpin Note' : 'Pin Note'}
                >
                  <Pin size={16} class={localPinned ? 'fill-current' : ''} />
                </button>

                <div
                  class="flex items-center gap-1.5 rounded-lg border border-transparent bg-slate-100/50 px-2.5 py-1.5 transition-all focus-within:border-indigo-200/50 focus-within:bg-white/80 hover:bg-white/50"
                >
                  <FolderOpen size={14} class="text-slate-400" />
                  <input
                    type="text"
                    value={localFolder || ''}
                    onchange={updateFolder}
                    placeholder="No Folder"
                    class="w-24 bg-transparent text-xs font-medium text-slate-600 outline-none placeholder:text-slate-400"
                  />
                </div>
              </div>
            {/if}
          {/if}
        </div>

        {#if !isCompactToolbar}
          <div class="flex items-center gap-1">
            {#if !noteStore.selectedNote.is_deleted}
              <button
                onclick={performUndo}
                disabled={!history.canUndo}
                class="rounded-lg p-2 transition-all hover:bg-white/50
              {history.canUndo
                  ? 'cursor-pointer text-slate-600 hover:text-slate-900'
                  : 'cursor-not-allowed text-slate-300'}"
                title="Undo (Ctrl+Z)"
              >
                <Undo2 size={18} />
              </button>

              <button
                onclick={performRedo}
                disabled={!history.canRedo}
                class="rounded-lg p-2 transition-all hover:bg-white/50
              {history.canRedo
                  ? 'cursor-pointer text-slate-600 hover:text-slate-900'
                  : 'cursor-not-allowed text-slate-300'}"
                title="Redo (Ctrl+Y)"
              >
                <Redo2 size={18} />
              </button>

              <div class="mx-1 h-4 w-px bg-slate-300/30"></div>

              <button
                onclick={copyToClipboard}
                class="group flex items-center gap-1.5 rounded-lg px-2 py-1.5 text-xs font-medium text-slate-500 transition-all hover:bg-white/50 hover:text-slate-700"
                title="Copy to Clipboard"
              >
                {#if isCopied}
                  <Check size={14} class="text-emerald-500" />
                  <span class="text-emerald-600">Copied</span>
                {:else}
                  <Copy size={14} />
                  <span class="hidden sm:inline">Copy</span>
                {/if}
              </button>

              <div class="mx-1 h-4 w-px bg-slate-300/30"></div>
            {:else}
              <button
                onclick={() =>
                  noteStore.selectedNote &&
                  noteStore.restore(noteStore.selectedNote.id)}
                class="group flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-medium text-slate-500 transition-all hover:bg-white/50 hover:text-emerald-600"
              >
                <RotateCcw size={14} />
                <span class="hidden sm:inline">Restore</span>
              </button>
            {/if}

            <button
              onclick={() =>
                noteStore.selectedNote &&
                noteStore.delete(noteStore.selectedNote.id)}
              class="rounded-lg p-2 text-slate-400 transition-all hover:bg-red-50 hover:text-red-500"
              title={noteStore.selectedNote.is_deleted
                ? 'Delete Permanently'
                : 'Move to Trash'}
            >
              {#if noteStore.selectedNote.is_deleted}
                <Trash2 size={18} class="stroke-red-500" />
              {:else}
                <Trash2 size={18} />
              {/if}
            </button>
          </div>
        {/if}

        {#if isCompactToolbar}
          <div class="flex items-center">
            <button
              onclick={() => (isMobileMenuOpen = !isMobileMenuOpen)}
              class="rounded-lg p-2 text-slate-500 transition-all hover:bg-white/50 hover:text-indigo-600"
            >
              {#if isMobileMenuOpen}
                <X size={20} />
              {:else}
                <MoreVertical size={20} />
              {/if}
            </button>
          </div>
        {/if}

        {#if isMobileMenuOpen}
          <div
            role="button"
            tabindex="0"
            class="fixed inset-0 z-40 bg-black/5 backdrop-blur-[1px]"
            onclick={() => (isMobileMenuOpen = false)}
            onkeydown={(e) => e.key === 'Escape' && (isMobileMenuOpen = false)}
          ></div>

          <div
            class="absolute top-16 right-2 z-50 flex w-64 flex-col gap-2 rounded-xl border border-white/60 bg-white/90 p-3 shadow-2xl backdrop-blur-xl dark:border-slate-700 dark:bg-slate-900/95"
            transition:slide={{ duration: 150 }}
          >
            {#if !noteStore.selectedNote.is_deleted}
              <div
                class="flex items-center gap-2 border-b border-slate-200/50 pb-2"
              >
                <button
                  onclick={togglePin}
                  class="flex items-center gap-2 rounded-lg p-2 text-sm font-medium transition-all
                    {localPinned
                    ? 'bg-indigo-50 text-indigo-600'
                    : 'text-slate-500 hover:bg-slate-100'}"
                >
                  <Pin size={16} class={localPinned ? 'fill-current' : ''} />
                </button>
                <div
                  class="flex flex-1 items-center gap-2 rounded-lg bg-slate-100 px-3 py-2 text-sm"
                >
                  <FolderOpen size={14} class="text-slate-400" />
                  <input
                    type="text"
                    value={localFolder || ''}
                    onchange={updateFolder}
                    placeholder="No Folder"
                    class="w-full bg-transparent outline-none"
                  />
                </div>
              </div>

              <div class="flex justify-between pt-1">
                <div class="flex gap-1">
                  <button
                    onclick={performUndo}
                    disabled={!history.canUndo}
                    class="rounded-lg p-2 text-slate-500 hover:bg-slate-100 disabled:opacity-30"
                  >
                    <Undo2 size={18} />
                  </button>
                  <button
                    onclick={performRedo}
                    disabled={!history.canRedo}
                    class="rounded-lg p-2 text-slate-500 hover:bg-slate-100 disabled:opacity-30"
                  >
                    <Redo2 size={18} />
                  </button>
                </div>
                <div class="flex gap-1 border-l border-slate-200 pl-2">
                  <button
                    onclick={copyToClipboard}
                    class="rounded-lg p-2 text-slate-500 hover:bg-slate-100"
                  >
                    {#if isCopied}
                      <Check size={18} class="text-emerald-500" />
                    {:else}
                      <Copy size={18} />
                    {/if}
                  </button>
                  <button
                    onclick={() =>
                      noteStore.selectedNote &&
                      noteStore.delete(noteStore.selectedNote.id)}
                    class="rounded-lg p-2 text-red-500 hover:bg-red-50"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              </div>
            {:else}
              <div class="flex flex-col gap-2">
                <button
                  onclick={() =>
                    noteStore.selectedNote &&
                    noteStore.restore(noteStore.selectedNote.id)}
                  class="flex w-full items-center justify-center gap-2 rounded-lg bg-slate-100 py-2 text-sm font-medium text-slate-600 hover:bg-emerald-50 hover:text-emerald-600"
                >
                  <RotateCcw size={16} />
                  Restore Note
                </button>
                <button
                  onclick={() =>
                    noteStore.selectedNote &&
                    noteStore.delete(noteStore.selectedNote.id)}
                  class="flex w-full items-center justify-center gap-2 rounded-lg bg-red-50 py-2 text-sm font-medium text-red-600 hover:bg-red-100"
                >
                  <Trash2 size={16} />
                  Delete Permanently
                </button>
              </div>
            {/if}
          </div>
        {/if}
      </header>

      <div
        class="mx-auto flex w-full max-w-3xl flex-1 flex-col overflow-hidden"
        in:fade={{ duration: 150 }}
      >
        <input
          type="text"
          bind:this={titleRef}
          value={localTitle}
          disabled={noteStore.selectedNote.is_deleted}
          oninput={(e) => handleInput(e, 'title')}
          class="w-full bg-transparent px-8 pt-8 pb-4 text-3xl font-bold text-slate-800 outline-none placeholder:text-slate-300/70 disabled:cursor-not-allowed disabled:opacity-50"
          placeholder="Untitled Note"
        />

        <textarea
          bind:this={contentRef}
          value={localContent}
          disabled={noteStore.selectedNote.is_deleted}
          oninput={(e) => handleInput(e, 'content')}
          class="custom-scrollbar w-full flex-1 resize-none bg-transparent px-8 py-2 text-lg leading-relaxed text-slate-600 outline-none placeholder:text-slate-300/70 disabled:cursor-not-allowed disabled:opacity-50"
          placeholder="Start typing your thoughts..."
          spellcheck="false"
        ></textarea>
      </div>

      <footer
        class="flex items-center justify-between border-t border-slate-200/30 bg-white/10 px-6 py-2 text-[10px] font-medium tracking-wider text-slate-400 uppercase select-none"
      >
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-1.5">
            <Type size={10} />
            <span>{wordCount} Words</span>
          </div>
          <div class="flex items-center gap-1.5">
            <span>{charCount} Chars</span>
          </div>
        </div>
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-1.5">
            {#if noteStore.syncState === 'saving'}
              <Loader2 size={10} class="animate-spin" />
              <span class="hidden sm:inline">Saving...</span>
            {:else if noteStore.syncState === 'saved'}
              <CheckCircle2 size={10} class="text-emerald-500" />
              <span class="hidden text-emerald-600 sm:inline">Saved</span>
            {:else if noteStore.syncState === 'error'}
              <span class="text-red-400">Error</span>
            {/if}
          </div>
          <div class="opacity-50">
            v{noteStore.selectedNote.version}
          </div>
        </div>
      </footer>
    {:else}
      <header
        data-tauri-drag-region
        class="flex h-14 min-h-[3.5rem] items-center px-4"
      >
        <button
          onclick={toggleSidebar}
          class="rounded-lg p-2 text-slate-400 transition-all hover:bg-white/50 hover:text-slate-600 {isSidebarOpen
            ? 'opacity-50'
            : 'text-indigo-500 opacity-100'}"
          title={isSidebarOpen ? 'Collapse Sidebar' : 'Expand Sidebar'}
        >
          <PanelLeft size={18} />
        </button>
      </header>

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
