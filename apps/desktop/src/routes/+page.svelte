<script lang="ts">
  import { noteStore } from '$lib/noteStore.svelte';
  import { settingsStore } from '$lib/settingsStore.svelte';
  import SettingsModal from '../components/SettingsModal.svelte';
  import Sidebar from '../components/Sidebar.svelte';
  import Editor from '../components/Editor.svelte';
  import { onMount } from 'svelte';
  import '../app.css';

  let isSidebarOpen = $state(true);

  onMount(() => {
    void noteStore.init();
    void settingsStore.init();
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
</script>

<SettingsModal />

<main
  class="flex h-screen w-screen overflow-hidden bg-gradient-to-br from-transparent to-black/5 p-3 text-slate-700 selection:bg-indigo-100 selection:text-indigo-900"
>
  <Sidebar bind:isOpen={isSidebarOpen} />
  <Editor bind:isSidebarOpen />
</main>
