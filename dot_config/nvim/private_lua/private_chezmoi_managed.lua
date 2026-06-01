-- Shared chezmoi state lookup. Consumed by lualine + oil.
-- Tracks two sets, keyed by absolute target path:
--   managed -- every target chezmoi owns          (`chezmoi managed`)
--   dirty   -- targets out of sync with the source (`chezmoi status`)
-- A dirty path is always also managed. Built synchronously on first require
-- (two ~30ms spawns, at lazy load) so the first render is correct, then
-- refreshed async after writes / on demand.
local M = {}

M.managed = {}
M.dirty = {}

-- Canonicalize a path for comparison so keys and lookups match regardless of
-- platform: forward slashes, no trailing slash, lowercased on Windows (its FS
-- is case-insensitive and nvim/chezmoi mix separators + drive-letter case).
local is_win = package.config:sub(1, 1) == "\\"
local function norm(path)
  path = path:gsub("\\", "/"):gsub("/+$", "")
  if is_win then
    path = path:lower()
  end
  return path
end

local home = norm(vim.fn.expand("~"))

local function managed_set(lines)
  local set = {}
  for _, line in ipairs(lines) do
    set[norm(home .. "/" .. line)] = true
  end
  return set
end

local function dirty_set(lines)
  -- each line is "XY <path>": status codes in cols 1-2, path from col 4
  local set = {}
  for _, line in ipairs(lines) do
    local path = line:sub(4)
    if path ~= "" then
      set[norm(home .. "/" .. path)] = true
    end
  end
  return set
end

-- async refresh of both sets; `cb` (optional) runs once both are rebuilt,
-- e.g. to re-render an open Oil buffer.
function M.refresh(cb)
  if vim.fn.executable("chezmoi") == 0 then
    if cb then
      vim.schedule(cb)
    end
    return
  end
  local pending = 2
  local function done()
    pending = pending - 1
    if pending == 0 then
      vim.schedule(function()
        pcall(vim.cmd, "redrawstatus")
        if cb then
          cb()
        end
      end)
    end
  end
  vim.system({ "chezmoi", "managed" }, { text = true }, function(obj)
    if obj.code == 0 then
      M.managed = managed_set(vim.split(obj.stdout, "\n", { trimempty = true }))
    end
    done()
  end)
  vim.system({ "chezmoi", "status" }, { text = true }, function(obj)
    if obj.code == 0 then
      M.dirty = dirty_set(vim.split(obj.stdout, "\n", { trimempty = true }))
    end
    done()
  end)
end

---@return boolean
function M.is_managed(path)
  return M.managed[norm(path)] == true
end

---@return boolean target differs from source (needs `chezmoi apply`/`re-add`)
function M.is_dirty(path)
  return M.dirty[norm(path)] == true
end

-- synchronous initial build so the first statusline / Oil render is accurate
if vim.fn.executable("chezmoi") == 1 then
  M.managed = managed_set(vim.fn.systemlist({ "chezmoi", "managed" }))
  M.dirty = dirty_set(vim.fn.systemlist({ "chezmoi", "status" }))
end
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    M.refresh()
  end,
})

return M
