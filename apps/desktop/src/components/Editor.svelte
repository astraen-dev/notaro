<script lang="ts">
  import { noteStore } from '$lib/noteStore.svelte';
  import { HistoryStore, type HistoryState } from '$lib/historyStore.svelte';
  import { fade, slide } from 'svelte/transition';
  import { onMount, onDestroy, tick } from 'svelte';
  import {
    PanelLeft,
    Trash,
    Pin,
    FolderOpen,
    Undo2,
    Redo2,
    Copy,
    Check,
    RotateCcw,
    Trash2,
    MoreVertical,
    X,
    Type,
    Loader2,
    CheckCircle2,
    PenLine,
    Scan,
    Shrink,
  } from '@lucide/svelte';

  // Props
  let { isSidebarOpen = $bindable() } = $props<{ isSidebarOpen: boolean }>();

  // Local State
  let isCopied = $state(false);
  let isMobileMenuOpen = $state(false);
  let isZenMode = $state(false);
  let editorSectionRef = $state<HTMLElement>();
  let editorWidth = $state(1000);
  let resizeObserver: ResizeObserver;

  // Form State
  let localTitle = $state('');
  let localContent = $state('');
  let localFolder = $state<string | null>(null);
  let localPinned = $state(false);
  let currentNoteId = $state<string | null>(null);

  // Refs
  let titleRef = $state<HTMLInputElement>();
  let contentRef = $state<HTMLTextAreaElement>();

  // History & Debounce
  const history = new HistoryStore();
  let timer: ReturnType<typeof setTimeout>;
  let lastInputTime = 0;
  const HISTORY_DEBOUNCE = 1000;

  // UI Metrics for Responsive Toolbar
  const UI_METRICS = {
    PADDING: 32,
    GAP_L: 16,
    GAP_S: 4,
    BTN: 40,
    FOLDER: 140,
    COPY: 70,
    RESTORE: 90,
    MENU: 40,
  };

  onMount(() => {
    if (editorSectionRef) {
      resizeObserver = new ResizeObserver((entries) => {
        for (const entry of entries) {
          editorWidth = entry.contentRect.width;
        }
      });
      resizeObserver.observe(editorSectionRef);
    }
    // Initial resize for content
    resizeTextarea();
  });

  onDestroy(() => {
    if (resizeObserver) resizeObserver.disconnect();
  });

  // Sync local state when selected note changes
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
      resizeTextarea();
    }
  });

  function resizeTextarea() {
    if (contentRef) {
      contentRef.style.height = 'auto';
      contentRef.style.height = contentRef.scrollHeight + 'px';
    }
  }

  // --- History Logic ---

  function getCurrentCursorState() {
    const field = document.activeElement === titleRef ? 'title' : 'content';
    const pos =
      (field === 'title'
        ? titleRef?.selectionStart
        : contentRef?.selectionStart) || 0;
    return { field: field as 'title' | 'content', pos };
  }

  async function applyHistoryState(state: HistoryState) {
    localTitle = state.title;
    localContent = state.content;
    saveProperties();
    await tick();
    resizeTextarea();
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

  // --- Saving & Updates ---

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

  function handleInput(e: Event, field: 'title' | 'content') {
    const target = e.target as HTMLInputElement | HTMLTextAreaElement;
    const val = target.value;
    const now = Date.now();

    if (field === 'content') resizeTextarea();

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
    timer = setTimeout(() => saveProperties(), 400);
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

  function toggleZenMode() {
    isZenMode = !isZenMode;
    // Auto-collapse sidebar in Zen Mode, restore if exiting
    if (isZenMode) isSidebarOpen = false;
  }

  // --- Derived UI ---

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
    let requiredWidth = UI_METRICS.PADDING + UI_METRICS.BTN + UI_METRICS.GAP_L;
    if (isDeleted) {
      requiredWidth += UI_METRICS.RESTORE + UI_METRICS.GAP_S + UI_METRICS.BTN;
    } else {
      const leftGroup = UI_METRICS.BTN + UI_METRICS.GAP_S + UI_METRICS.FOLDER;
      const rightGroup =
        UI_METRICS.BTN * 3 + UI_METRICS.COPY + UI_METRICS.GAP_S * 4;
      requiredWidth += leftGroup + UI_METRICS.GAP_L + rightGroup;
    }
    return editorWidth < requiredWidth;
  });
</script>

<svelte:window onkeydown={handleKeydown} />

<section
  bind:this={editorSectionRef}
  class="relative flex w-full flex-1 flex-col overflow-hidden rounded-2xl border border-white/60 bg-white/60 shadow-2xl backdrop-blur-2xl transition-all duration-300"
>
  {#if noteStore.selectedNote}
    <!-- Trash Banner -->
    {#if noteStore.selectedNote.is_deleted}
      <div
        class="flex w-full items-center justify-center gap-2 bg-red-50/80 px-4 py-2 text-xs font-medium text-red-600 dark:bg-red-900/20 dark:text-red-400"
      >
        <Trash size={14} />
        <span>This note is in the trash. Editing is disabled.</span>
      </div>
    {/if}

    <!-- Toolbar Header -->
    <header
      data-tauri-drag-region
      class="flex min-h-[3.5rem] items-center justify-between gap-4 border-b border-slate-200/30 bg-white/10 px-4 transition-opacity duration-500
      {isZenMode ? 'opacity-0 hover:opacity-100' : 'opacity-100'}"
    >
      <div class="flex items-center gap-4">
        <button
          onclick={() => (isSidebarOpen = !isSidebarOpen)}
          class="rounded-lg p-2 text-slate-400 transition-all hover:bg-white/50 hover:text-slate-600 {isSidebarOpen
            ? 'opacity-50'
            : 'text-indigo-500 opacity-100'}"
          title={isSidebarOpen ? 'Collapse Sidebar' : 'Expand Sidebar'}
        >
          <PanelLeft size={18} />
        </button>

        {#if !noteStore.selectedNote.is_deleted && !isCompactToolbar}
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
      </div>

      <!-- Desktop Actions -->
      <div class="flex items-center gap-1">
        {#if !isCompactToolbar}
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
        {/if}

        <!-- Zen Mode Toggle -->
        <div class="mx-1 h-4 w-px bg-slate-300/30"></div>
        <button
          onclick={toggleZenMode}
          class="rounded-lg p-2 text-slate-400 transition-all hover:bg-indigo-50 hover:text-indigo-500"
          title={isZenMode ? 'Exit Zen Mode' : 'Enter Zen Mode'}
        >
          {#if isZenMode}
            <Shrink size={18} />
          {:else}
            <Scan size={18} />
          {/if}
        </button>

        <!-- Mobile/Compact Menu Trigger -->
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
      </div>

      <!-- Compact Menu Dropdown -->
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

    <!-- Editor Input Areas -->
    <div
      class="custom-scrollbar flex-1 overflow-y-auto scroll-smooth"
      in:fade={{ duration: 150 }}
    >
      <div class="mx-auto flex min-h-full w-full max-w-3xl flex-col px-8 py-8">
        <input
          type="text"
          bind:this={titleRef}
          value={localTitle}
          disabled={noteStore.selectedNote.is_deleted}
          oninput={(e) => handleInput(e, 'title')}
          class="mb-4 w-full bg-transparent text-4xl font-bold tracking-tight text-slate-800 outline-none placeholder:text-slate-300/70 disabled:cursor-not-allowed disabled:opacity-50"
          placeholder="Untitled Note"
        />

        <textarea
          bind:this={contentRef}
          value={localContent}
          disabled={noteStore.selectedNote.is_deleted}
          oninput={(e) => handleInput(e, 'content')}
          class="w-full flex-1 resize-none bg-transparent text-lg leading-relaxed text-slate-600 outline-none placeholder:text-slate-300/70 disabled:cursor-not-allowed disabled:opacity-50"
          placeholder="Start typing your thoughts..."
          spellcheck="false"
          style="min-height: 60vh;"
        ></textarea>

        <!-- Bottom Spacer to allow scrolling past end -->
        <div class="h-20 w-full"></div>
      </div>
    </div>

    <!-- Footer Stats -->
    <footer
      class="absolute bottom-0 z-10 flex w-full items-center justify-between border-t border-slate-200/30 bg-white/40 px-6 py-2 text-[10px] font-medium tracking-wider text-slate-400 uppercase backdrop-blur-md transition-opacity duration-500 select-none
      {isZenMode ? 'opacity-0 hover:opacity-100' : 'opacity-100'}"
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
    <!-- Empty State -->
    <header
      data-tauri-drag-region
      class="flex h-14 min-h-[3.5rem] items-center px-4"
    >
      <button
        onclick={() => (isSidebarOpen = !isSidebarOpen)}
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
      <div class="rounded-full bg-white/30 p-6 shadow-sm">
        <PenLine size={64} class="text-indigo-300 opacity-30" />
      </div>
      <div class="text-center">
        <p class="text-lg font-medium text-slate-500">No Note Selected</p>
        <p class="text-sm opacity-60">
          Press <kbd class="font-sans font-bold text-indigo-400">Ctrl+N</kbd> to
          create a new note
        </p>
      </div>
    </div>
  {/if}
</section>
