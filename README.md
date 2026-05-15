# Awsum for Neovim

Neovim plugin for the [Awsum](https://awsum-lang.org) programming language (`.aww` files).

## Features

- Syntax highlighting (Tree-sitter)
- Code formatting (`awsum format`)
- Inline diagnostics (errors + warnings)
- Quick fixes (code actions)
- Document symbols (Structure view / breadcrumbs)
- Workspace symbol search

All of the above are powered by the `awsum` compiler's bundled language server — there is no separate `awsum-lsp` to install. As long as the `awsum` binary is on your `PATH`, the plugin will spawn it as `awsum lsp` and route every editor request through it.

## Requirements

- Neovim **0.12+** (uses the built-in `vim.lsp.config` and `vim.treesitter` APIs).
- The `awsum` compiler on your `PATH` — see [awsum-lang/awsum](https://github.com/awsum-lang/awsum).
- A C compiler, to compile the bundled Tree-sitter parser once at install time:
  - **macOS**: `xcode-select --install` (Xcode Command Line Tools).
  - **Linux**: `build-essential` (Debian/Ubuntu) / `base-devel` (Arch) / equivalent.
  - **Windows**: run from a "Developer Command Prompt for VS" after installing [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) so MSVC `cl.exe` + `link.exe` are on `PATH`. MinGW `gcc` also works if available. Standalone LLVM Clang alone is _not_ sufficient — it relies on `link.exe` from MSVC.

## Install

The snippets below pin to **`v0.0.4.1`**. Replace it with the version of `awsum` you have installed — plugin and compiler must match (see [Versioning](#versioning)).

The tree-sitter parser binary is compiled the first time you open a `.aww` file (~1 second, cached on disk afterward). You don't need to wire an install-time build hook — the plugin handles it automatically.

### Option 1: vim.pack (built-in, no extra dependencies)

Neovim 0.12+ ships [`vim.pack`](https://neovim.io/doc/user/pack/) as its built-in plugin manager. Add to `~/.config/nvim/init.lua`:

```lua
vim.pack.add({
  { src = "https://github.com/awsum-lang/awsum-nvim", version = "v0.0.4.1" },
})

-- To update later:
--   :lua vim.pack.update({ 'awsum-nvim' })  -- opens a confirm tabpage
--   :w                                      -- (in the confirm buffer) applies
--   :restart                                -- reloads plugins with new code

-- To uninstall: remove the vim.pack.add call above, then:
--   :lua vim.pack.del({ 'awsum-nvim' })
```

### Option 2: lazy.nvim

If you already use [lazy.nvim](https://lazy.folke.io/), save the spec to `~/.config/nvim/lua/plugins/awsum.lua`:

```lua
return {
  "awsum-lang/awsum-nvim",
  tag = "v0.0.4.1",
  ft = "aww",
}

-- To update later:
--   :Lazy update awsum-nvim   -- pulls the new tag, reloads the plugin

-- To uninstall: delete this spec file (or remove the entry from your inline
-- setup table), then :Lazy clean to remove the on-disk plugin directory.
```

If your config keeps plugin specs inline, drop the `return` and paste the table into your existing `require("lazy").setup({ ... })` call instead.

### Option 3: Manual

```sh
git clone --branch v0.0.4.1 https://github.com/awsum-lang/awsum-nvim \
  ~/.local/share/nvim/site/pack/awsum/start/awsum-nvim
```

To update later:

```sh
cd ~/.local/share/nvim/site/pack/awsum/start/awsum-nvim
git fetch --tags
git checkout v0.0.4.2   # or whatever new tag matches your awsum
```

To uninstall:

```sh
rm -rf ~/.local/share/nvim/site/pack/awsum/start/awsum-nvim
```

## Usage

Syntax highlighting and diagnostics activate automatically on `.aww` files. Other LSP features are invoked the standard Neovim way.

### Formatting

One-shot, from inside Neovim:

```vim
:lua vim.lsp.buf.format()
```

Bind a keymap (in `~/.config/nvim/init.lua`):

```lua
vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { desc = 'Format buffer' })
```

Format on save:

```lua
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.aww',
  callback = function() vim.lsp.buf.format() end,
})
```

### Diagnostics

| Action                                       | Default keymap (Neovim 0.10+) | Ex-command                         |
| -------------------------------------------- | ----------------------------- | ---------------------------------- |
| Open diagnostic at cursor in floating window | `<C-w>d`                      | `:lua vim.diagnostic.open_float()` |
| Jump to next diagnostic                      | `]d`                          | `:lua vim.diagnostic.goto_next()`  |
| Jump to previous diagnostic                  | `[d`                          | `:lua vim.diagnostic.goto_prev()`  |

### Code actions, symbols

```vim
:lua vim.lsp.buf.code_action()
:lua vim.lsp.buf.document_symbol()
:lua vim.lsp.buf.workspace_symbol()
```

Bind to your own keymaps as you prefer.

## Configuration

The plugin works with zero configuration. To override defaults, call `setup` with the fields you want to change:

```lua
require("awsum").setup({
  cmd = { "/custom/path/awsum", "lsp", "--stdio" },
  root_markers = { ".git", "awsum.json" },
})
```

With lazy.nvim, this is idiomatic via the `opts` field:

```lua
{
  "awsum-lang/awsum-nvim",
  tag = "v0.0.4.1",
  ft = "aww",
  opts = { cmd = { "/custom/path/awsum", "lsp", "--stdio" } },
}
```

## Versioning

`awsum-nvim A.B.C` is built and tested against `awsum A.B.C`. Mismatched versions are not supported — at startup the language server compares the plugin's expected version against its own and shows a notification on mismatch.

## Related

- Compiler (hosts `awsum lsp`): [awsum-lang/awsum](https://github.com/awsum-lang/awsum)
- Tree-sitter grammar: [awsum-lang/tree-sitter-awsum](https://github.com/awsum-lang/tree-sitter-awsum)
- VSCode extension: [awsum-lang/awsum-vscode](https://github.com/awsum-lang/awsum-vscode)
- Zed extension: [awsum-lang/awsum-zed](https://github.com/awsum-lang/awsum-zed)
- IntelliJ Platform plugin: [awsum-lang/awsum-intellij](https://github.com/awsum-lang/awsum-intellij)
- Website: [awsum-lang.org](https://awsum-lang.org)

## License

MIT — see [LICENSE](LICENSE).
