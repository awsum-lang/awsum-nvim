local M = {}

local version = require("awsum.version")

-- WORKAROUND: the awsum LSP server advertises `semanticTokensProvider` but the
-- handler returns null (`textDocument/semanticTokens/full` is not implemented
-- on the server). We strip the capability client-side so Neovim stops asking
-- and doesn't surface a `no handler for ...` warning every time a buffer opens.
-- Remove this once the server either implements the handler or stops
-- advertising the capability.
local function strip_unhandled_server_capabilities(client, _init_result)
  client.server_capabilities.semanticTokensProvider = nil
end

local defaults = {
  cmd = { "awsum", "lsp", "--stdio" },
  filetypes = { "aww" },
  root_markers = { ".git" },
  init_options = {
    expectedAwsumVersion = version,
    preferButtonsOverLinks = true,
  },
  on_init = strip_unhandled_server_capabilities,
}

local function deep_merge(base, override)
  local result = {}
  for k, v in pairs(base) do
    result[k] = (type(v) == "table") and vim.deepcopy(v) or v
  end
  for k, v in pairs(override or {}) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

local state = {
  config = defaults,
  activated = false,
}

function M.setup(opts)
  state.config = deep_merge(defaults, opts or {})
  -- Protocol-contract with the server — not user policy.
  state.config.init_options.expectedAwsumVersion = version
  state.config.init_options.preferButtonsOverLinks = true
  state.config.on_init = strip_unhandled_server_capabilities
  if state.activated then
    M.activate()
  end
end

local function start_treesitter(buf)
  local ok, err = pcall(vim.treesitter.start, buf, "awsum")
  if not ok then
    vim.notify(
      "awsum-nvim: tree-sitter highlighting unavailable ("
        .. tostring(err)
        .. ").\nRun `:lua require('awsum').build_parser()` to compile the parser, "
        .. "or set `build = function() require('awsum').build_parser() end` in your plugin spec.",
      vim.log.levels.WARN
    )
  end
end

function M.activate()
  vim.lsp.config("awsum", state.config)
  vim.lsp.enable("awsum")

  vim.treesitter.language.register("awsum", "aww")

  local group = vim.api.nvim_create_augroup("awsum_treesitter", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "aww",
    callback = function(args)
      start_treesitter(args.buf)
    end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "aww" then
      start_treesitter(buf)
    end
  end

  state.activated = true
end

function M.build_parser()
  return require("awsum.build_parser").build()
end

return M
