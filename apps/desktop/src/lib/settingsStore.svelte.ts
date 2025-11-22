import { invoke } from '@tauri-apps/api/core';

export interface UserSettings {
  theme_mode: 'system' | 'light' | 'dark';
  accent_hue: number;
  font_family: 'sans' | 'serif' | 'mono';
  font_size: number;
}

class SettingsStore {
  // Default state
  settings = $state<UserSettings>({
    theme_mode: 'system',
    accent_hue: 250,
    font_family: 'sans',
    font_size: 14,
  });

  isOpen = $state(false);

  // Remove constructor logic that relies on Tauri or DOM being ready immediately
  constructor() {}

  async init() {
    try {
      this.settings = await invoke('get_settings');
    } catch (e) {
      console.error('Failed to load settings:', e);
    }
  }

  async update(partial: Partial<UserSettings>) {
    this.settings = { ...this.settings, ...partial };
    try {
      await invoke('save_settings', { settings: this.settings });
    } catch (e) {
      console.error('Failed to save settings:', e);
    }
  }

  toggle() {
    this.isOpen = !this.isOpen;
  }
}

export const settingsStore = new SettingsStore();
