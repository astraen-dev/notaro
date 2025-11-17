# Notaro Desktop

This is the cross-platform desktop application for Notaro, built for Windows, macOS, and Linux.

## Technology Stack

- **Framework:** [Tauri v2](https://tauri.app/)
- **Backend Language:** Rust
- **Frontend Framework:** SvelteKit
- **Frontend Language:** TypeScript
- **Styling:** (To be decided, e.g., Tailwind CSS)

## Architectural Role

The Tauri application provides a native desktop window (a webview) that renders the SvelteKit frontend. The Rust backend
part of this app (`src-tauri`) acts as a bridge, consuming the `notaro_core` crate natively to perform all database
operations and business logic locally.

## Getting Started (from monorepo root)

1. **Install Dependencies:**
   ```bash
   pnpm install
   ```
2. **Run in Development Mode:**
   This will open the desktop app with hot-reloading for the frontend.
   ```bash
   pnpm dev:desktop
   ```
3. **Build the Application:**
   This will create a native executable/installer for your platform.
   ```bash
   pnpm tauri build
   ```

## License

This package is licensed under the MIT License. See the [LICENSE](../../LICENSE) file in the root of the repository for the full text.
