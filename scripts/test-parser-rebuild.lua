-- Regression test: a parser binary built from other sources is rebuilt.
-- Plugin managers update the checkout in place and leave the untracked binary
-- behind, so without this check an upgrade keeps the old parser for good.
-- Needs a C compiler. Run with `just test`.

local awsum = require("awsum")
local bp = require("awsum.build_parser")

local function read(path)
  local f = io.open(path, "rb")
  if not f then
    return nil
  end
  local s = f:read("a")
  f:close()
  return s
end

local function mtime(path)
  local st = assert(vim.uv.fs_stat(path))
  return st.mtime.sec * 1e9 + st.mtime.nsec
end

-- Start from a binary built from the current sources.
bp.build()

-- A binary that matches the sources is kept.
local before = mtime(bp.binary_path())
assert(awsum.ensure_parser(), "ensure_parser failed with a current binary")
assert(mtime(bp.binary_path()) == before, "a binary matching the sources was rebuilt")

-- A binary built from other sources is rebuilt.
local f = assert(io.open(bp.fingerprint_path(), "wb"))
f:write("stale")
f:close()
assert(awsum.ensure_parser(), "ensure_parser failed with a stale binary")
assert(read(bp.fingerprint_path()) == bp.fingerprint(), "a binary built from other sources was not rebuilt")

-- A binary with no recorded fingerprint (built by 0.0.7 or earlier) is rebuilt.
os.remove(bp.fingerprint_path())
assert(awsum.ensure_parser(), "ensure_parser failed with an unfingerprinted binary")
assert(read(bp.fingerprint_path()) == bp.fingerprint(), "a binary without a recorded fingerprint was not rebuilt")

-- Neovim loads the rebuilt parser (nothing else matches `parser/awsum.*`).
local ok, err = pcall(vim.treesitter.language.add, "awsum")
assert(ok, "Neovim cannot load the parser: " .. tostring(err))

io.stdout:write("OK — stale parser binaries are rebuilt, current ones are kept\n")
