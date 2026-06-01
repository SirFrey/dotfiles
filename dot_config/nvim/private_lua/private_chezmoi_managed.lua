-- Shared chezmoi-managed lookup. Consumed by lualine + oil.
-- The set is built synchronously on first require (one ~30ms spawn, at lazy
-- load) so the first render is correct, then refreshed async after writes.
local M = {}

local home = vim.fn.expand("~")
M.managed = {}

local function build(lines)
  local set = {}
  for _, line in ipairs(lines) do
    set[home .. "/" .. line] = true
  end
  return set
end

-- async refresh; keeps the set fresh without blocking on every write
function M.refresh()
  if vim.fn.executable("chezmoi") == 0 then
    return
  end
  vim.system({ "chezmoi", "managed" }, { text = true }, function(obj)
    if obj.code ~= 0 then
      return
    end
    M.managed = build(vim.split(obj.stdout, "\n", { trimempty = true }))
    vim.schedule(function()
      pcall(vim.cmd, "redrawstatus")
    end)
  end)
end

---@param path string absolute path; trailing slash (oil dirs) is normalized away
---@return boolean
function M.is_managed(path)
  return M.managed[(path:gsub("/$", ""))] == true
end

-- synchronous initial build so the first statusline / Oil render is accurate
if vim.fn.executable("chezmoi") == 1 then
  M.managed = build(vim.fn.systemlist({ "chezmoi", "managed" }))
end
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    M.refresh()
  end,
})

return M
