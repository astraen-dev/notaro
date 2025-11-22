<script lang="ts">
  import { noteStore } from '$lib/noteStore.svelte';
  import { settingsStore } from '$lib/settingsStore.svelte';
  import { fade } from 'svelte/transition';
  import {
    Cloud,
    Settings,
    Plus,
    Pin,
    Trash,
    Folder,
    Search,
    FileText,
  } from '@lucide/svelte';

  let { isOpen = $bindable() } = $props<{ isOpen: boolean }>();

  const formatDate = (iso: string) => {
    const date = new Date(iso);
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
        title="New Note"
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
