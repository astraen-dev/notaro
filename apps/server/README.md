# Notaro Server

This is the self-hostable sync server for Notaro. It acts as the central hub for all clients to synchronize their data.

## Technology Stack

- **Language:** Rust
- **Web Framework:** (To be decided)
- **WebSocket Library:** (To be decided)
- **Deployment:** Docker

## Architectural Role

The server's primary responsibilities are:

- To accept WebSocket connections from authenticated clients (or, in this case, a single user).
- To receive note changes (`diffs` or `CRDTs`) from one client.
- To broadcast those changes to all other connected clients.
- To persist the canonical state of the notes in its own database, using the logic from `notaro_core`.

## Getting Started (from monorepo root)

1. **Run in Development Mode:**
   ```bash
   cargo run -p notaro_server
   ```
2. **Build for Production:**
   ```bash
   cargo build -p notaro_server --release
   ```
3. **Build the Docker Image:**
   (Once the `Dockerfile` is complete)
   ```bash
   docker build -t notaro_server -f ./apps/server/Dockerfile .
   ```
   