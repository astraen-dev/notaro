# Notaro Core

This crate is the shared core business logic for the entire Notaro application suite. It is written in pure Rust and
contains no platform-specific UI code.

## Purpose

The `notaro_core` library is the single source of truth for:

- Database schema and queries (via SQLite).
- Data models (e.g., `Note`, `Change`, etc.).
- Syncing logic and conflict resolution algorithms.
- Markdown parsing and plaintext handling.

## Technology Stack

- **Language:** Rust
- **Database:** Rusqlite (for SQLite interaction)
- **Serialization:** Serde

## How It's Used

This library is designed to be consumed by all Notaro applications in different ways:

- **Desktop & Server:** Consumed directly as a native Rust crate via a `path` dependency in their `Cargo.toml`.
- **Mobile (Flutter):** Consumed via a Foreign Function Interface (FFI) using `flutter_rust_bridge` to generate bindings
  between Rust and Dart.
- **Web (SvelteKit):** Compiled to **WebAssembly (WASM)** using `wasm-pack` and `wasm-bindgen` to run the core logic
  directly in the browser.

## Key Commands (from monorepo root)

- **Check the crate:** `cargo check -p notaro_core`
- **Run tests:** `cargo test -p notaro_core`

## License

This package is licensed under the MIT License. See the [LICENSE](../../LICENSE) file in the root of the repository for the full text.
