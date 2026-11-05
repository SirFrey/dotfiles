-- Run deferred startup work only while you aren't typing.
-- Each task waits until no key has been pressed for its `quiet_ms`, and at most
-- one task runs per event-loop turn, so a keystroke never waits behind more
-- than one task and the screen redraws between tasks.
local M = {}
local uv = vim.uv

-- Startup counts as activity: the first keys usually come right after paint.
local last_key = uv.now()
vim.on_key(function()
  last_key = uv.now()
end, vim.api.nvim_create_namespace("idle"))

local queue = {} ---@type { fn: fun(), quiet: integer }[]
local timer = assert(uv.new_timer())
local running = false
local last_run = -1

local function tick()
  local now = uv.now()
  -- uv.now() is cached per loop turn: this stops a backlog of scheduled ticks
  -- from running several tasks back to back without a redraw in between
  if now == last_run then
    return
  end
  for i, task in ipairs(queue) do
    if now - last_key >= task.quiet then
      table.remove(queue, i)
      last_run = now
      local ok, err = pcall(task.fn)
      if not ok then
        vim.notify("idle task failed: " .. tostring(err), vim.log.levels.ERROR)
      end
      break
    end
  end
  if #queue == 0 then
    timer:stop()
    running = false
  end
end

---@param fn fun()
---@param quiet_ms? integer ms without a keypress before `fn` may run (default 100)
function M.run(fn, quiet_ms)
  table.insert(queue, { fn = fn, quiet = quiet_ms or 100 })
  if not running then
    running = true
    timer:start(16, 16, vim.schedule_wrap(tick))
  end
end

return M
