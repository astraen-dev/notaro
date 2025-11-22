<script lang="ts">
  import { noteStore } from '$lib/noteStore.svelte';
  import { settingsStore } from '$lib/settingsStore.svelte';
  import { fade } from 'svelte/transition';
  import {
    Cloud,
    Settings,
    Plus,
    Pin,
    PinOff,
    Trash,
    Trash2,
    Folder,
    Search,
    FileText,
    ArchiveRestore,
  } from '@lucide/svelte';

  let { isOpen = $bindable() } = $props<{ isOpen: boolean }>();
  let searchInput = $state<HTMLInputElement>();

  export function focusSearch() {
    searchInput?.focus();
  }

  const formatSmartDate = (iso: string) => {
    const date = new Date(iso);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) {
      return new Intl.DateTimeFormat('en-US', {
        hour: 'numeric',
        minute: 'numeric',
      }).format(date);
    } else if (days < 7) {
      return new Intl.DateTimeFormat('en-US', { weekday: 'short' }).format(
        date
      );
    }
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
    }).format(date);
  };

  function selectNote(id: string) {
    noteStore.select(id);
    if (window.innerWidth < 768) {
      isOpen = false;
    }
  }

  function handleKeydown(e: KeyboardEvent, id: string) {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      selectNote(id);
    }
  }

  function handleQuickAction(e: Event, action: () => void) {
    e.stopPropagation();
    action();
  }
</script>

<!-- Mobile Backdrop -->
{#if isOpen}
  <div
    class="fixed inset-0 z-30 bg-black/20 backdrop-blur-[2px] md:hidden"
    onclick={() => (isOpen = false)}
    transition:fade={{ duration: 200 }}
    role="presentation"
  ></div>
{/if}

<!-- Sidebar Container -->
<aside
  class="fixed inset-y-3 left-3 z-40 flex h-[calc(100vh-1.5rem)] flex-col overflow-hidden rounded-2xl border border-white/50 bg-white/90 shadow-2xl backdrop-blur-xl transition-all duration-300 ease-[cubic-bezier(0.2,0,0,1)] md:relative md:inset-auto
  md:h-auto md:bg-white/40 md:shadow-xl
  {isOpen
    ? 'w-72 translate-x-0 opacity-100 md:mr-3'
    : 'w-0 -translate-x-4 border-0 opacity-0 md:mr-0'}"
>
  <!-- Header -->
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
        title="New Note (Ctrl+N)"
      >
        <Plus size={20} />
      </button>
    </div>
  </div>

  <!-- Filter Tabs -->
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

  <!-- Dynamic Folders -->
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

  <!-- Search -->
  <div class="px-4 py-2">
    <div class="group relative">
      <Search
        class="absolute top-1/2 left-3 -translate-y-1/2 text-slate-400 transition-colors group-focus-within:text-indigo-500"
        size={16}
      />
      <input
        type="text"
        bind:this={searchInput}
        bind:value={noteStore.searchQuery}
        placeholder="Search... (Ctrl+F)"
        class="w-full rounded-xl border border-transparent bg-slate-50/50 py-2 pr-3 pl-9 text-sm transition-all outline-none placeholder:text-slate-400 focus:border-indigo-200/50 focus:bg-white/70"
      />
    </div>
  </div>

  <!-- Note List -->
  <div class="custom-scrollbar flex-1 space-y-1 overflow-y-auto p-2">
    {#each noteStore.filteredNotes as note (note.id)}
      <div
        role="button"
        tabindex="0"
        onclick={() => selectNote(note.id)}
        onkeydown={(e) => handleKeydown(e, note.id)}
        class="group relative w-full cursor-pointer overflow-hidden rounded-xl border p-3 text-left transition-all duration-200 select-none
        {noteStore.selectedId === note.id
          ? 'border-indigo-100/50 bg-white/90 shadow-sm ring-1 ring-indigo-50'
          : 'border-transparent hover:border-white/20 hover:bg-white/40'}"
      >
        <!-- Active Indicator -->
        {#if noteStore.selectedId === note.id}
          <div
            class="absolute top-0 left-0 h-full w-1 bg-indigo-500/80"
            transition:fade
          ></div>
        {/if}

        <span class="mb-1 flex w-full items-start justify-between">
          <span
            class="flex items-center gap-1.5 truncate pr-2 font-semibold {noteStore.selectedId ===
            note.id
              ? 'text-slate-900'
              : 'text-slate-600'}"
          >
            {#if note.is_pinned}
              <Pin size={11} class="fill-current text-indigo-400 opacity-100" />
            {/if}
            {note.title || 'Untitled Note'}
          </span>
          <span
            class="mt-1 text-[10px] font-medium whitespace-nowrap opacity-50"
          >
            {formatSmartDate(note.updated_at)}
          </span>
        </span>

        <span class="block h-4 truncate text-xs opacity-60">
          {note.content || 'No additional text'}
        </span>

        <!-- Hover Quick Actions -->
        <div
          class="absolute right-2 bottom-2 flex gap-1 opacity-0 transition-opacity duration-200 group-focus-within:opacity-100 group-hover:opacity-100"
        >
          {#if !note.is_deleted}
            <button
              onclick={(e) =>
                handleQuickAction(e, () =>
                  noteStore.save(
                    note.id,
                    note.title,
                    note.content,
                    note.folder,
                    !note.is_pinned
                  )
                )}
              class="rounded-md bg-white/90 p-1.5 text-slate-500 shadow-sm transition-colors hover:bg-white hover:text-indigo-600"
              title={note.is_pinned ? 'Unpin' : 'Pin'}
            >
              {#if note.is_pinned}
                <PinOff size={12} />
              {:else}
                <Pin size={12} />
              {/if}
            </button>
            <button
              onclick={(e) =>
                handleQuickAction(e, () => noteStore.delete(note.id))}
              class="rounded-md bg-white/90 p-1.5 text-slate-500 shadow-sm transition-colors hover:bg-white hover:text-red-500"
              title="Move to Trash"
            >
              <Trash2 size={12} />
            </button>
          {:else}
            <!-- Restore from Trash Action -->
            <button
              onclick={(e) =>
                handleQuickAction(e, () => noteStore.restore(note.id))}
              class="rounded-md bg-white/90 p-1.5 text-slate-500 shadow-sm transition-colors hover:bg-white hover:text-emerald-600"
              title="Restore"
            >
              <ArchiveRestore size={12} />
            </button>
          {/if}
        </div>
      </div>
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
