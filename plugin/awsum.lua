if vim.fn.has("nvim-0.12") == 0 then
  vim.notify(
    "awsum-nvim requires Neovim 0.12 or newer (current: " .. tostring(vim.version()) .. ").",
    vim.log.levels.ERROR
  )
  return
end

require("awsum").activate()
