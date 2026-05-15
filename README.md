# Awsum for Neovim

Neovim plugin for the [Awsum](https://awsum-lang.org) programming language (`.aww` files).

## Features

- Syntax highlighting (Tree-sitter)
- Format on save
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
    - **Windows**: clang, gcc, or MSVC Build Tools on `PATH`.

## Install

### Option 1: vim.pack (built-in, no extra dependencies)

Neovim 0.12+ ships [`vim.pack`](https://neovim.io/doc/user/pack/) as its built-in plugin manager. Place these two blocks in `~/.config/nvim/init.lua`:

```lua
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "awsum-nvim"
       and (ev.data.kind == "install" or ev.data.kind == "update") then
      require("awsum").build_parser()
    end
  end,
})

vim.pack.add({ "https://github.com/awsum-lang/awsum-nvim" })
```

### Option 2: lazy.nvim

If you already use [lazy.nvim](https://lazy.folke.io/), save the spec to `~/.config/nvim/lua/plugins/awsum.lua`:

```lua
return {
  "awsum-lang/awsum-nvim",
  build = function() require("awsum").build_parser() end,
  ft = "aww",
}
```

If your config keeps plugin specs inline, drop the `return` and paste the table into your existing `require("lazy").setup({ ... })` call instead.

### Option 3: Manual

```sh
git clone https://github.com/awsum-lang/awsum-nvim \
  ~/.local/share/nvim/site/pack/awsum/start/awsum-nvim
cd ~/.local/share/nvim/site/pack/awsum/start/awsum-nvim
nvim --headless --noplugin -c "set rtp+=." \
     -c "lua require('awsum.build_parser').build()" -c "q"
```

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
  build = function() require("awsum").build_parser() end,
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
