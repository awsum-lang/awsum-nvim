local M = {}

local function plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
end

local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function find_cc()
  local candidates = {}
  if vim.env.CC and vim.env.CC ~= "" then
    table.insert(candidates, vim.env.CC)
  end
  if vim.fn.has("mac") == 1 then
    vim.list_extend(candidates, { "clang", "cc", "gcc" })
  elseif is_windows() then
    vim.list_extend(candidates, { "clang", "gcc", "cl" })
  else
    vim.list_extend(candidates, { "cc", "gcc", "clang" })
  end
  for _, cc in ipairs(candidates) do
    if vim.fn.executable(cc) == 1 then
      return cc
    end
  end
  return nil
end

local function compiler_install_hint()
  if vim.fn.has("mac") == 1 then
    return "macOS: run `xcode-select --install`"
  elseif is_windows() then
    return "Windows: install MSVC Build Tools or MinGW"
  else
    return "Linux: install `build-essential` (apt) or `base-devel` (pacman) or equivalent"
  end
end

function M.build()
  local root = plugin_root()
  local src_dir = root .. "/src"
  local out_dir = root .. "/parser"
  local ext = is_windows() and ".dll" or ".so"
  local out_path = out_dir .. "/awsum" .. ext

  vim.fn.mkdir(out_dir, "p")

  local cc = find_cc()
  if not cc then
    error(
      "awsum-nvim: no C compiler found on PATH (tried $CC, clang, cc, gcc, cl).\n"
        .. compiler_install_hint()
    )
  end

  local cmd
  if is_windows() and cc == "cl" then
    cmd = {
      cc,
      "/nologo",
      "/LD",
      "/O2",
      "/I",
      src_dir,
      src_dir .. "/parser.c",
      src_dir .. "/scanner.c",
      "/Fe:" .. out_path,
    }
  elseif is_windows() then
    -- clang/gcc on Windows: -fPIC is unsupported on the MSVC-compatible target
    -- (and a no-op on Windows in general, since all code is position-independent
    -- by default). -shared still produces a .dll.
    cmd = {
      cc,
      "-O2",
      "-shared",
      "-I",
      src_dir,
      src_dir .. "/parser.c",
      src_dir .. "/scanner.c",
      "-o",
      out_path,
    }
  else
    cmd = {
      cc,
      "-O2",
      "-fPIC",
      "-shared",
      "-I",
      src_dir,
      src_dir .. "/parser.c",
      src_dir .. "/scanner.c",
      "-o",
      out_path,
    }
  end

  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    error(
      "awsum-nvim: parser compilation failed.\n"
        .. "Command: "
        .. table.concat(cmd, " ")
        .. "\nstderr: "
        .. (result.stderr or "")
    )
  end

  vim.notify("awsum-nvim: built " .. out_path, vim.log.levels.INFO)
end

return M
