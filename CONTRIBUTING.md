# Contributing to Notaro

First off, thank you for considering contributing to Notaro! It's people like you that make Notaro such a great tool.

This document provides guidelines for contributing to the project. Please feel free to propose changes to this document
in a pull request.

## Code of Conduct

This project and everyone participating in it is governed by the [Notaro Code of Conduct](CODE_OF_CONDUCT.md). By
participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Bugs are tracked as [GitHub issues](https://github.com/astraen-dev/notaro/issues). Before submitting a bug report, please
perform a search to see if the problem has already been reported. If it has and the issue is still open, add a comment
to the existing issue instead of opening a new one.

When you are creating a bug report, please include as many details as possible by filling out
the [Bug Report template](https://github.com/astraen-dev/notaro/issues/new?template=bug_report.yml).

### Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub issues](https://github.com/astraen-dev/notaro/issues). Use
the [Feature Request template](https://github.com/astraen-dev/notaro/issues/new?template=feature_request.yml) to define the
problem and your suggested solution.

For larger ideas, it's often best to start a [discussion](https://github.com/astraen-dev/notaro/discussions) first to gauge
interest from the community and maintainers.

### Your First Code Contribution

Unsure where to begin contributing to Notaro? You can start by looking through `good first issue` and `help wanted`
issues:

- [Good first issues](https://github.com/astraen-dev/notaro/labels/good%20first%20issue) - issues which should only require
  a few lines of code, and a test or two.
- [Help wanted issues](https://github.com/astraen-dev/notaro/labels/help%20wanted) - issues which should be a bit more
  involved than `good first issue` issues.

### Pull Requests

The process described here has several goals:

- Maintain Notaro's quality
- Fix problems that are important to users
- Engage the community in working toward the best possible Notaro
- Enable a sustainable system for Notaro's maintainers to review contributions

Please follow these steps to have your contribution considered by the maintainers:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes (`pnpm lint` and `pnpm test` if applicable).
5. Make sure your code lints (`pnpm format`).
6. Issue that pull request!

## Development Setup

This is a monorepo using `pnpm` workspaces, `Cargo` workspaces, and Flutter.

1. **Install Core Dependencies:**
   - [Node.js](https://nodejs.org/) (LTS version)
   - [pnpm](https://pnpm.io/installation)
   - [Rust](https://www.rust-lang.org/tools/install) (via `rustup`)
   - [Flutter SDK](https://docs.flutter.dev/get-started/install)

2. **Install project dependencies:**
   From the root of the repository, run:

   ```bash
   pnpm install
   ```

3. **Run applications:**
   Refer to the `README.md` files in each `apps/*` directory for specific instructions, or use the root-level scripts:

   ```bash
   # Run the desktop app
   pnpm dev:desktop

   # Run the web app
   pnpm dev:web

   # Run the mobile app (from apps/mobile)
   cd apps/mobile && flutter run
   ```

## Style Guides

### JavaScript/TypeScript/Svelte

We use [Prettier](https://prettier.io/) for code formatting and [ESLint](https://eslint.org/) for linting. The
configurations are in the root `.prettierrc` and `eslint.config.js` files within each app.

Run `pnpm format:js` to format your code.

### Rust

We use `rustfmt` and `clippy` for code style and linting. The configurations are in the root `rustfmt.toml` and
`Cargo.toml`.

Run `pnpm format:rust` to format and `pnpm lint:rust` to check your code.

### Dart/Flutter

We use the standard `dart format` and `flutter analyze` tools.

Run `pnpm format:dart` to format and `pnpm lint:dart` to check your code.

A pre-commit hook is set up with Husky and lint-staged to automatically format and lint your changes before you commit.
