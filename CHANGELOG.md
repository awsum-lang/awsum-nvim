# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

`awsum-nvim` is versioned 1:1 with the `awsum` compiler — the plugin's `A.B.C` is exactly the `awsum` `A.B.C` it targets. Every `awsum` release ships a matching plugin release, the plugin is never released ahead of the compiler, and only the latest `awsum` release is supported.

Until `awsum 1.0.0`, the project does not follow SemVer — every release increments only the patch (`0.0.1 → 0.0.2 …`), and any release may break. The 1:1 lockstep above is the contract that does hold: within a single `0.0.x`, the plugin and the `awsum` it ships against are mutually compatible.

## [Unreleased]

### Added

- `:AwsumRestartLspServer` user command — stops the `awsum lsp` process and starts a new one with the same `init_options`. Implemented as `vim.lsp.enable('awsum', false)` followed by `vim.lsp.enable('awsum')`. Useful after a local `stack install` of a new `awsum` build, or to clear any in-memory state on the server. No default keymap.

### Fixed

- Bare type references (`Int32` in `unused : Int32`, leaves of `A -> B`, `A | B`) now highlight as `@type`. Previously only types inside an explicit `Maybe Int32`-style application were caught; bare leaves of arrow / union / signature-type positions fell through. Picked up from upstream `tree-sitter-awsum` highlight queries.

## [0.0.4] - 2026-05-15

### Added

- Initial release. Thin LSP client to `awsum lsp --stdio` (subcommand of the `awsum` compiler binary). Every editor feature is computed inside the compiler and pushed over LSP:
  - **Syntax highlighting** via the Tree-sitter grammar from [`awsum-lang/tree-sitter-awsum`](https://github.com/awsum-lang/tree-sitter-awsum). Parser sources (`src/parser.c`, `src/scanner.c`, `src/tree_sitter/parser.h`) and query files are vendored at the ref recorded in `.tree-sitter-awsum-rev`. The plugin self-builds `parser/awsum.so` (`.dll` on Windows) from the vendored sources via the system C compiler on the first `.aww` open, then caches the binary on disk. No `nvim-treesitter` or external grammar-installer dependency, no install-time build hook required from the user.
  - **Format on save** via `textDocument/formatting` — same algorithm as `awsum format`. Bound to `vim.lsp.buf.format()` / `BufWritePre`.
  - **Inline diagnostics** via `textDocument/publishDiagnostics` (debounced 500 ms server-side; `error` / `warning` severity honoured by Neovim's `vim.diagnostic` display).
  - **Quick fixes** via `textDocument/codeAction` — compiler-supplied fixes only; surfaced via `vim.lsp.buf.code_action()`.
  - **Document symbols** via `textDocument/documentSymbol` — drives `vim.lsp.buf.document_symbol()` and outline plugins like `aerial.nvim`.
  - **Workspace symbol search** via `workspace/symbol`.
- Declarative lockstep version check: the plugin passes `initializationOptions: { expectedAwsumVersion, preferButtonsOverLinks: true }` and the server warns on mismatch via `window/showMessageRequest`. Neovim maps that to `vim.ui.select` — a native cmdline chooser by default, or the user's Telescope / fzf-lua / dressing.nvim picker if overridden. The expected version is the single source of truth from `lua/awsum/version.lua`.
- Neovim 0.12+ minimum: the plugin uses `vim.lsp.config` + `vim.lsp.enable` (no `nvim-lspconfig` dependency) and `vim.treesitter.start` (no `nvim-treesitter` dependency, after that plugin was archived in April 2026).
- Three documented install paths in `README.md`: `vim.pack` (built-in Neovim 0.12 plugin manager), `lazy.nvim`, and manual placement under `~/.local/share/nvim/site/pack/`.
- `justfile` with user-facing recipes:
  - `install-local` / `uninstall-local` — symlink the working copy into Neovim's native pack path for local development.
  - `build-parser` — compile the vendored parser via headless Neovim.
  - `vendor-update <ref>` — re-sync vendored `tree-sitter-awsum` snapshot from the sibling repo at the given ref.
  - `check` — drift check between vendored sources and the pinned ref (same as CI).
  - `release` — tag and push the version from `lua/awsum/version.lua`. Mirrors the recipe in `awsum/justfile`, `awsum-vscode/justfile`, `awsum-zed/justfile`, `awsum-intellij/justfile`.
- Release workflow: pushing a `v*` tag verifies the tag matches `lua/awsum/version.lua`, re-runs CI on the tagged commit (drift check + parser build on Linux / macOS / Windows), and publishes a GitHub Release whose notes point to this changelog. No installable artifact is uploaded — Neovim plugins are installed straight from the git tag, and GitHub auto-attaches a source archive to each Release.
- CI: vendored-files drift check against the pinned `tree-sitter-awsum` ref, plus a parser-build smoke test on Linux / macOS / Windows.
- `CONTRIBUTING.md` is intentionally absent for v0.0.4 — the project's CONTRIBUTING flow lives at the workspace level (private root). Will be added if external contributions start arriving.

### Known limitations

- The compiler currently advertises `semanticTokensProvider` capability but does not implement `textDocument/semanticTokens/full`. Without intervention, Neovim's native LSP client would log a `no handler for ...` warning on every buffer open. The plugin strips the capability client-side in `on_init` as a workaround; remove that strip once the compiler ships a real handler (or stops advertising the capability).
