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

## Developer Certificate of Origin

By contributing to `awsum-nvim` you certify the [Developer Certificate of Origin](https://developercertificate.org/) (DCO) for your contribution — a short statement that you wrote the patch yourself, or otherwise have the right to submit it under the project's [Apache-2.0 license](LICENSE). The full text is at the link above.

After cloning, run once:

```bash
just setup-dev
```

This installs the `prepare-commit-msg` hook from [scripts/git-hooks/](scripts/git-hooks/) (via per-clone `core.hooksPath`), which adds a `Signed-off-by` trailer to every commit you make in this clone:

```
Signed-off-by: Your Name <you@example.com>
```

The trailer uses the name and email from your `[user]` section in `~/.gitconfig` (the same one used for signed commits below). No manual flags, no global gitconfig changes. The setup is per-clone — repeat in each clone of the repo.

## Signed commits

Separately from the DCO trailer above, the `main` branch requires signed commits — every commit you push to a PR needs a verified signature (GPG or SSH), otherwise the merge button stays grey.

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
