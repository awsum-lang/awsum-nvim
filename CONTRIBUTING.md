# Contributing to `awsum-nvim`

Thanks for your interest in contributing.

## Development setup

See [README.md](README.md) for an overview. Quick reference:

```sh
just install-local         # Symlink this checkout into ~/.local/share/nvim/site/pack/awsum/start/ and build the parser
just uninstall-local       # Remove the symlink; vendored parser binary in parser/ is left intact
just build-parser          # Compile parser/awsum.{so,dll} from vendored src/parser.c + src/scanner.c
just vendor-update <ref>   # Re-pull parser sources and queries from the sibling tree-sitter-awsum at <ref>
just check                 # Verify vendored files match tree-sitter-awsum at the ref in .tree-sitter-awsum-rev — CI gates on this
```

The plugin targets Neovim 0.12+ and uses only built-in APIs — no `nvim-lspconfig`, no `nvim-treesitter`, no other third-party plugin. Local development needs Neovim 0.12+ on `PATH`, the `awsum` CLI on `PATH` (for end-to-end testing through `vim.lsp`), and a C compiler (so `just build-parser` can compile the vendored Tree-sitter sources into `parser/awsum.so` / `.dll`).

After `just install-local`, any subsequent `nvim file.aww` auto-loads the plugin from the symlinked checkout — edits to Lua sources take effect on the next file open. The parser binary only rebuilds when `just build-parser` is rerun (or when `start_treesitter`'s self-heal triggers because it's missing).

## Tree-sitter vendoring

The plugin ships generated parser sources (`src/parser.c`, `src/scanner.c`, `src/tree_sitter/parser.h`) and Tree-sitter queries (`queries/awsum/*.scm`) directly, pinned to a specific ref of [`awsum-lang/tree-sitter-awsum`](https://github.com/awsum-lang/tree-sitter-awsum) recorded in [.tree-sitter-awsum-rev](.tree-sitter-awsum-rev). The rationale and full mechanism are in [README.md](README.md#related); the short version is that only a C compiler is required on the user's machine, not the `tree-sitter-cli` toolchain or any `nvim-treesitter`-class manager.

When upstream ships a new tag, sync with `just vendor-update <tag>`: the script copies parser sources and queries from the sibling `../tree-sitter-awsum` checkout at the given ref and bumps `.tree-sitter-awsum-rev`. CI gates `just check` on every push and PR — vendored files must match upstream at the pinned ref byte-for-byte.

## Signed commits

The `main` branch requires signed commits — every commit you push to a PR needs a verified signature, otherwise the merge button stays grey.

Minimal `~/.gitconfig` for SSH signing:

```ini
[user]
	email = ...
	name = ...
	signingkey = ~/.ssh/id_ed25519.pub
[commit]
	gpgsign = true
[gpg]
	format = ssh
```

For GPG signing instead, set `gpg.format = openpgp` (or omit — that's the default) and point `signingkey` at your GPG key ID. The option name `gpgsign` is git's historical name for "sign this thing" and applies regardless of format.

The same key file must be added to GitHub Settings → SSH and GPG keys as a **Signing Key** (a separate category from Authentication Key, even if you reuse the same file). Verify locally:

```bash
git commit -S -m "test" --allow-empty
git log --show-signature -1
```

If you already made unsigned commits on a feature branch, retroactively sign with:

```bash
git rebase --exec 'git commit --amend --no-edit -S' <range>
```

then force-push your branch.

## Pull requests

- Open against `main`. CI (`ci.yml`) must be green before merge — that includes `just check` passing.
- For user-visible changes, add a bullet under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md). Infrastructure-only changes (CI, dev tooling, internal refactors) still get an entry so the next release notes are complete.
- Versions are 1:1 with the `awsum` compiler. Bumping the version touches one place — `return "A.B.C"` in [lua/awsum/version.lua](lua/awsum/version.lua) — and the release workflow verifies the tag matches it.
