<script lang="ts">
  import { noteStore } from '$lib/noteStore.svelte';
  import '../app.css';

  // Debounce logic for auto-saving
  let timer: ReturnType<typeof setTimeout>;

  function handleInput(e: Event, field: 'title' | 'content') {
    if (!noteStore.selectedNote) return;

    const val = (e.target as HTMLInputElement | HTMLTextAreaElement).value;
    const title = field === 'title' ? val : noteStore.selectedNote.title;
    const content = field === 'content' ? val : noteStore.selectedNote.content;

    // Optimistic UI update logic is already in the store's save method,
    // but for typing speed we just trigger the save after a pause.
    clearTimeout(timer);
    timer = setTimeout(() => {
      if (noteStore.selectedNote) {
        noteStore.save(noteStore.selectedNote.id, title, content);
      }
    }, 500);
  }

  function handleDelete() {
    if (noteStore.selectedNote) {
      noteStore.delete(noteStore.selectedNote.id);
    }
  }
</script>

<main class="flex h-screen w-screen gap-4 p-4 font-sans">
  <!-- SIDEBAR -->
  <aside
    class="flex w-64 flex-col overflow-hidden rounded-2xl border border-white/30 bg-white/40 shadow-xl backdrop-blur-md transition-all"
  >
    <div class="flex items-center justify-between border-b border-white/20 p-4">
      <h1 class="font-bold text-gray-700">Notaro</h1>
      <button
        onclick={() => noteStore.add()}
        class="rounded-lg bg-blue-500/90 p-1 px-3 text-sm text-white shadow-md transition-colors hover:bg-blue-600"
      >
        + New
      </button>
    </div>

    <div class="flex-1 space-y-1 overflow-y-auto p-2">
      {#each noteStore.notes as note (note.id)}
        <button
          onclick={() => noteStore.select(note.id)}
          class="w-full rounded-xl border border-transparent p-3 text-left transition-all duration-200
          {noteStore.selectedId === note.id
            ? 'border-white/40 bg-white/60 text-blue-900 shadow-sm'
            : 'text-gray-600 hover:bg-white/30'}"
        >
          <div class="truncate font-medium">{note.title || 'Untitled'}</div>
          <div class="truncate text-xs text-gray-400">
            {new Date(note.updated_at).toLocaleDateString()}
          </div>
        </button>
      {/each}

      {#if noteStore.notes.length === 0}
        <div class="mt-10 text-center text-sm text-gray-400">No notes yet.</div>
      {/if}
    </div>
  </aside>

  <!-- EDITOR -->
  <section
    class="relative flex flex-1 flex-col overflow-hidden rounded-2xl border border-white/40 bg-white/60 shadow-2xl backdrop-blur-xl"
  >
    {#if noteStore.selectedNote}
      <div class="flex h-full flex-col">
        <!-- Toolbar -->
        <div
          class="flex items-center justify-between border-b border-gray-100/50 p-4"
        >
          <input
            type="text"
            value={noteStore.selectedNote.title}
            oninput={(e) => handleInput(e, 'title')}
            class="w-full bg-transparent text-2xl font-bold text-gray-800 placeholder-gray-400 outline-none"
            placeholder="Note Title"
          />
          <!-- Updated to call the script function -->
          <button
            onclick={handleDelete}
            class="rounded-lg p-2 text-red-400 transition-colors hover:bg-red-50 hover:text-red-600"
            title="Delete Note"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M3 6h18"></path>
              <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path>
              <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>
            </svg>
          </button>
        </div>

        <!-- Content Area -->
        <textarea
          value={noteStore.selectedNote.content}
          oninput={(e) => handleInput(e, 'content')}
          class="w-full flex-1 resize-none bg-transparent p-6 text-lg leading-relaxed font-light text-gray-700 outline-none"
          placeholder="Start typing..."
        ></textarea>

        <div
          class="flex justify-between border-t border-gray-100/50 px-6 py-2 text-xs text-gray-400"
        >
          <span>ID: {noteStore.selectedNote.id.slice(0, 8)}...</span>
          <span>v{noteStore.selectedNote.version}</span>
        </div>
      </div>
    {:else}
      <div class="flex h-full items-center justify-center text-gray-400">
        <p>Select a note to start editing</p>
      </div>
    {/if}
  </section>
</main>
