<script lang="ts">
  import { settingsStore, type UserSettings } from '$lib/settingsStore.svelte';
  import { X, Moon, Sun, Monitor } from 'lucide-svelte';
  import { fade, scale } from 'svelte/transition';

  // Define typed structures
  interface ThemeOption {
    value: UserSettings['theme_mode'];
    icon: typeof Sun;
    label: string;
  }

  interface FontOption {
    value: UserSettings['font_family'];
    label: string;
  }

  const themes: ThemeOption[] = [
    { value: 'light', icon: Sun, label: 'Light' },
    { value: 'dark', icon: Moon, label: 'Dark' },
    { value: 'system', icon: Monitor, label: 'System' },
  ];

  const fonts: FontOption[] = [
    { value: 'sans', label: 'Sans Serif' },
    { value: 'serif', label: 'Serif' },
    { value: 'mono', label: 'Monospace' },
  ];

  function handleBackdropKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape' || e.key === 'Enter' || e.key === ' ') {
      settingsStore.toggle();
    }
  }
</script>

{#if settingsStore.isOpen}
  <!-- Backdrop -->
  <div
    role="button"
    tabindex="0"
    class="fixed inset-0 z-50 flex cursor-default items-center justify-center bg-black/20 backdrop-blur-sm transition-all"
    onclick={() => settingsStore.toggle()}
    onkeydown={handleBackdropKeydown}
    transition:fade={{ duration: 200 }}
    aria-label="Close Settings"
  >
    <!-- Modal Content -->
    <div
      role="dialog"
      aria-modal="true"
      tabindex="-1"
      class="w-96 cursor-auto rounded-2xl border border-white/50 bg-white/80 p-6 shadow-2xl backdrop-blur-xl outline-none dark:border-slate-700 dark:bg-slate-900/80"
      onclick={(e) => e.stopPropagation()}
      onkeydown={(e) => e.stopPropagation()}
      transition:scale={{ start: 0.95, duration: 200 }}
    >
      <div class="mb-6 flex items-center justify-between">
        <h2 class="text-xl font-bold text-slate-800 dark:text-slate-100">
          Appearance
        </h2>
        <button
          onclick={() => settingsStore.toggle()}
          class="rounded-full p-1 text-slate-500 hover:bg-slate-200 dark:hover:bg-slate-700"
          aria-label="Close"
        >
          <X size={20} />
        </button>
      </div>

      <div class="space-y-6">
        <!-- Theme Toggle -->
        <div class="space-y-2">
          <span
            id="theme-label"
            class="text-xs font-semibold tracking-wider text-slate-500 uppercase"
          >
            Theme
          </span>
          <div
            role="group"
            aria-labelledby="theme-label"
            class="flex rounded-lg bg-slate-200/50 p-1 dark:bg-slate-800"
          >
            {#each themes as theme (theme.value)}
              {@const Icon = theme.icon}
              <button
                class="flex flex-1 items-center justify-center gap-2 rounded-md py-1.5 text-sm font-medium transition-all
                {settingsStore.settings.theme_mode === theme.value
                  ? 'bg-white text-indigo-600 shadow-sm dark:bg-slate-700 dark:text-indigo-400'
                  : 'text-slate-500 hover:text-slate-700'}"
                onclick={() =>
                  settingsStore.update({ theme_mode: theme.value })}
              >
                <Icon size={14} />
                {theme.label}
              </button>
            {/each}
          </div>
        </div>

        <!-- Accent Color Slider -->
        <div class="space-y-2">
          <div class="flex justify-between">
            <label
              for="accent-hue"
              class="text-xs font-semibold tracking-wider text-slate-500 uppercase"
            >
              Accent Color
            </label>
            <!-- Preview Dot -->
            <div
              class="h-4 w-4 rounded-full shadow-sm"
              style="background-color: hsl({settingsStore.settings
                .accent_hue}, 80%, 60%)"
            ></div>
          </div>
          <input
            id="accent-hue"
            type="range"
            min="0"
            max="360"
            value={settingsStore.settings.accent_hue}
            oninput={(e) =>
              settingsStore.update({
                accent_hue: parseInt(e.currentTarget.value),
              })}
            class="h-2 w-full appearance-none rounded-lg bg-gradient-to-r from-red-500 via-green-500 to-blue-500"
            aria-label="Adjust accent color hue"
          />
        </div>

        <!-- Typography -->
        <div class="space-y-2">
          <span
            id="typography-label"
            class="text-xs font-semibold tracking-wider text-slate-500 uppercase"
          >
            Typography
          </span>
          <div
            role="group"
            aria-labelledby="typography-label"
            class="grid grid-cols-3 gap-2"
          >
            {#each fonts as font (font.value)}
              <button
                class="rounded-lg border border-transparent px-3 py-2 text-sm transition-all
                {settingsStore.settings.font_family === font.value
                  ? 'border-indigo-200 bg-indigo-50 text-indigo-700 dark:border-indigo-500/30 dark:bg-indigo-900/30 dark:text-indigo-300'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-400'}"
                onclick={() =>
                  settingsStore.update({ font_family: font.value })}
              >
                {font.label}
              </button>
            {/each}
          </div>
        </div>
      </div>
    </div>
  </div>
{/if}
