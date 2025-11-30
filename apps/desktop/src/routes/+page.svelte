<script lang="ts">
  import { noteStore } from '$lib/noteStore.svelte';
  import { settingsStore } from '$lib/settingsStore.svelte';
  import SettingsModal from '../components/SettingsModal.svelte';
  import Sidebar from '../components/Sidebar.svelte';
  import Editor from '../components/Editor.svelte';
  import { onMount } from 'svelte';
  import '../app.css';

  let isSidebarOpen = $state(true);
  let sidebarRef = $state<Sidebar>();

  // Track system preference reactively
  let systemPrefersDark = $state(false);

  onMount(() => {
    void noteStore.init();
    void settingsStore.init();

    // Initialize and listen to system preference changes
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    systemPrefersDark = mediaQuery.matches;

    const handler = (e: MediaQueryListEvent) => {
      systemPrefersDark = e.matches;
    };

    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  });

  // Global Theme Management
  $effect(() => {
    const root = document.documentElement;
    const s = settingsStore.settings;

    // TODO: should find fonts dynamically?
    const fonts = {
      sans: '"Inter", sans-serif',
      serif: '"Merriweather", serif',
      mono: '"JetBrains Mono", monospace',
    };
    root.style.setProperty('--font-main', fonts[s.font_family] || fonts.sans);
    root.style.setProperty('--font-size-base', `${s.font_size}px`);
    root.style.setProperty('--accent-hue', s.accent_hue.toString());

    // Calculate theme based on Store AND Reactive System State
    const isDark =
      s.theme_mode === 'dark' ||
      (s.theme_mode === 'system' && systemPrefersDark);

    if (isDark) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  });

  function handleGlobalKeydown(e: KeyboardEvent) {
    if (e.metaKey || e.ctrlKey) {
      if (e.key === 'n') {
        e.preventDefault();
        noteStore.add();
      }
      if (e.key === 'f') {
        e.preventDefault();
        if (!isSidebarOpen) isSidebarOpen = true;
        sidebarRef?.focusSearch();
      }
      if (e.key === ',') {
        e.preventDefault();
        settingsStore.toggle();
      }
    }
  }
</script>

<svelte:window onkeydown={handleGlobalKeydown} />

<SettingsModal />

<main
  class="flex h-screen w-screen overflow-hidden bg-gradient-to-br from-transparent to-black/5 p-3 text-slate-700 selection:bg-indigo-100 selection:text-indigo-900 dark:text-slate-200 dark:selection:bg-indigo-900/50 dark:selection:text-indigo-100"
>
  <Sidebar bind:this={sidebarRef} bind:isOpen={isSidebarOpen} />
  <Editor bind:isSidebarOpen />
</main>
