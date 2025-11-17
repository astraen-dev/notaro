# Notaro Web

This is the browser-based web application for Notaro, allowing access to notes from any modern web browser.

## Technology Stack

- **Framework:** SvelteKit
- **Language:** TypeScript
- **Styling:** Tailwind CSS

## Architectural Role

The web app is a pure Single-Page Application (SPA). It does not have a persistent Rust backend like the Tauri app.
Instead, it will:

1. Load the `notaro_core` crate compiled to **WebAssembly (WASM)** to handle local state and database interactions
   (using SQLite compiled for the web).
2. Communicate with the `notaro_server` via a WebSocket for real-time syncing.

## Getting Started (from monorepo root)

1. **Install Dependencies:**
   ```bash
   pnpm install
   ```
2. **Run the Development Server:**
   ```bash
   pnpm dev:web
   ```
3. **Build for Production:**
   ```bash
   pnpm build:web
   ```

## License

This package is licensed under the MIT License. See the [LICENSE](../../LICENSE) file in the root of the repository for the full text.
