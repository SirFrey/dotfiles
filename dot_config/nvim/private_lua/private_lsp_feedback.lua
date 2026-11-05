-- Visible feedback while waiting on language servers and formatters.
--  * LSP requests you trigger (hover, definition, references, rename, ...)
--    show "<action> · waiting for <server>" with a spinner if the reply takes
--    longer than DELAY_MS, and clear the moment it arrives. Before this, a
--    first `K` while tsc was still loading the project sat silent for 1.5s+.
--  * Keys pressed before a language server has attached wait for it (with a
--    message) instead of failing or falling back to :Man.
--  * <space>f shows which formatter is running until it finishes.
local M = {}

local DELAY_MS = 200
local GROUP = "lsp_feedback"

local labels = {
  ["textDocument/hover"] = "Hover",
  ["textDocument/definition"] = "Go to definition",
  ["textDocument/declaration"] = "Go to declaration",
  ["textDocument/typeDefinition"] = "Go to type definition",
  ["textDocument/implementation"] = "Find implementations",
  ["textDocument/references"] = "Find references",
  ["textDocument/rename"] = "Rename",
  ["textDocument/prepareRename"] = "Rename",
  ["textDocument/codeAction"] = "Code actions",
  ["textDocument/signatureHelp"] = "Signature help",
  ["textDocument/documentSymbol"] = "Document symbols",
  ["workspace/symbol"] = "Workspace symbols",
  ["textDocument/prepareCallHierarchy"] = "Call hierarchy",
  ["callHierarchy/incomingCalls"] = "Incoming calls",
  ["callHierarchy/outgoingCalls"] = "Outgoing calls",
  ["textDocument/formatting"] = "Format",
  ["textDocument/rangeFormatting"] = "Format",
}

local configured = false
local function notif()
  local n = require("fidget.notification")
  if not configured then
    configured = true
    n.set_config(GROUP, {
      name = false,
      icon = require("fidget.spinner").animate("dots"),
      icon_on_left = true,
      ttl = 60, -- safety net: never leave a spinner up if a reply is lost
    }, true)
  end
  return n
end

local function show(key, msg, annote)
  local ok, n = pcall(notif)
  if ok then
    n.notify(msg, vim.log.levels.INFO, { group = GROUP, key = key, annote = annote, skip_history = true })
    -- draw now: fidget otherwise renders on its next poll (up to ~100ms later)
    pcall(function()
      n.poller:poll_once()
    end)
    vim.cmd.redraw()
  else
    vim.api.nvim_echo({ { msg .. (annote and (" · " .. annote) or "") } }, false, {})
  end
end

local function hide(key)
  if package.loaded["fidget.notification"] then
    require("fidget.notification").remove(GROUP, key)
  end
end

-- pending[label] = { count, clients = {name=true}, timer, shown }
local pending = {}
-- labels whose next request was already waiting on server start: show at once
local show_now = {}

local function annote_for(p)
  return "waiting for " .. table.concat(vim.tbl_keys(p.clients), ", ")
end

vim.api.nvim_create_autocmd("LspRequest", {
  group = vim.api.nvim_create_augroup("LspFeedback", { clear = true }),
  callback = function(ev)
    local req = ev.data.request
    local label = labels[req.method]
    if not label then
      return
    end
    local key = label .. ":" .. ev.data.client_id .. ":" .. ev.data.request_id
    if req.type == "pending" then
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      local p = pending[label] or { count = 0, clients = {}, ids = {} }
      pending[label] = p
      p.count = p.count + 1
      p.ids[key] = true
      p.clients[client and client.name or "server"] = true
      if show_now[label] and not p.shown then
        show_now[label] = nil
        p.shown = true
        show(label, label, annote_for(p))
      elseif not p.timer and not p.shown then
        p.timer = vim.defer_fn(function()
          p.timer = nil
          if p.count > 0 then
            p.shown = true
            show(label, label, annote_for(p))
          end
        end, DELAY_MS)
      elseif p.shown then
        show(label, label, annote_for(p))
      end
    elseif req.type == "complete" or req.type == "cancel" then
      local p = pending[label]
      if not p or not p.ids[key] then
        return
      end
      p.ids[key] = nil
      p.count = p.count - 1
      if p.count <= 0 then
        pending[label] = nil
        if p.timer then
          pcall(p.timer.stop, p.timer)
        end
        if p.shown then
          hide(label)
        end
      end
    end
  end,
})

-- Is a language server going to attach to this buffer? Loads the (idle-deferred)
-- LSP setup first so the answer is known right away.
local function lsp_expected(bufnr)
  pcall(function()
    require("lazy").load({ plugins = { "mason-lspconfig.nvim" } })
  end)
  local ft = vim.bo[bufnr].filetype
  for name in pairs(vim.lsp._enabled_configs or {}) do
    local cfg = vim.lsp.config[name]
    if cfg and cfg.filetypes and vim.tbl_contains(cfg.filetypes, ft) then
      return true
    end
  end
  return false
end

--- Run `fn` once a client supporting `method` is attached to the current buffer.
--- If none is attached yet but one is expected, waits for it with a message;
--- otherwise calls `fallback` (or reports that no server handles this file).
---@param method string
---@param fn fun()
---@param fallback? fun()
function M.with_client(method, fn, fallback)
  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr, method = method }) > 0 then
    return fn()
  end
  local label = labels[method] or "LSP"
  local key = "wait:" .. bufnr
  local cursor = vim.api.nvim_win_get_cursor(0)
  local win = vim.api.nvim_get_current_win()
  local setup_loaded = package.loaded["mason-lspconfig"] ~= nil
  if not setup_loaded then
    -- Deciding whether a server is coming loads the LSP setup (~50-100ms of
    -- work). Post the message and let it draw first, then load.
    show(key, label, "waiting for language server to start")
    vim.defer_fn(function()
      M._wait_for_client(bufnr, win, cursor, method, fn, fallback, label, key, true)
    end, 30)
    return
  end
  M._wait_for_client(bufnr, win, cursor, method, fn, fallback, label, key, false)
end

function M._wait_for_client(bufnr, win, cursor, method, fn, fallback, label, key, shown)
  if #vim.lsp.get_clients({ bufnr = bufnr, method = method }) > 0 then
    hide(key)
    return fn()
  end
  if not lsp_expected(bufnr) and #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
    if shown then
      hide(key)
    end
    if fallback then
      return fallback()
    end
    return vim.notify("No language server for this file", vim.log.levels.WARN)
  end
  if not shown then
    -- decided first so files without a server don't flash the message
    show(key, label, "waiting for language server to start")
  end
  local done = false
  local id
  local function finish(run)
    if done then
      return
    end
    done = true
    hide(key)
    pcall(vim.api.nvim_del_autocmd, id)
    -- only act if you're still where you asked
    if run and vim.api.nvim_get_current_win() == win and vim.api.nvim_get_current_buf() == bufnr
      and vim.deep_equal(vim.api.nvim_win_get_cursor(0), cursor) then
      show_now[label] = true -- no gap between "server starting" and "waiting for <server>"
      fn()
      show_now[label] = nil
    end
  end
  id = vim.api.nvim_create_autocmd("LspAttach", {
    buffer = bufnr,
    callback = function()
      if #vim.lsp.get_clients({ bufnr = bufnr, method = method }) > 0 then
        vim.schedule(function()
          finish(true)
        end)
      end
    end,
  })
  vim.defer_fn(function()
    if not done then
      finish(false)
      vim.notify(label .. ": language server didn't start within 20s", vim.log.levels.WARN)
    end
  end, 20000)
end

--- Run a shell command in the background with a spinner ("<title> · <annote>")
--- if it takes longer than DELAY_MS, then report success or the error.
---@param title string
---@param annote string
---@param cmd string[]
---@param opts? { done_msg?: string, on_done?: fun(ok: boolean, stderr: string), quiet_error?: fun(stderr: string): boolean }
function M.run(title, annote, cmd, opts)
  opts = opts or {}
  local key = "run:" .. title .. ":" .. annote
  local timer = vim.defer_fn(function()
    show(key, title, annote)
  end, DELAY_MS)
  vim.system(cmd, { text = true }, vim.schedule_wrap(function(obj)
    pcall(timer.stop, timer)
    hide(key)
    local ok = obj.code == 0
    local stderr = vim.trim(obj.stderr or "")
    if ok then
      if opts.done_msg then
        vim.notify(opts.done_msg, vim.log.levels.INFO)
      end
    elseif not (opts.quiet_error and opts.quiet_error(stderr)) then
      vim.notify(title .. " failed: " .. (stderr ~= "" and stderr or ("exit code " .. obj.code)), vim.log.levels.ERROR)
    end
    if opts.on_done then
      opts.on_done(ok, stderr)
    end
  end))
end

--- Show "<title> · <annote>" with a spinner right away (for actions you just
--- triggered) until `is_done()` returns true, then call `on_done`.
---@param title string
---@param annote string
---@param is_done fun(): boolean
---@param on_done? fun()
function M.until_done(title, annote, is_done, on_done)
  local key = "until:" .. title .. ":" .. annote
  show(key, title, annote)
  local timer = assert(vim.uv.new_timer())
  local started = vim.uv.now()
  timer:start(50, 50, vim.schedule_wrap(function()
    if timer:is_closing() then
      return
    end
    local timed_out = vim.uv.now() - started > 30000
    if is_done() or timed_out then
      timer:stop()
      timer:close()
      hide(key)
      if on_done and not timed_out then
        -- results (e.g. diagnostics) are published right after the job ends
        vim.defer_fn(on_done, 50)
      end
    end
  end))
end

--- <space>f: conform format with a visible "Formatting · <formatter>" while it runs.
function M.format()
  local conform = require("conform")
  local bufnr = vim.api.nvim_get_current_buf()
  local names = vim.tbl_map(function(f)
    return f.name
  end, conform.list_formatters_to_run(bufnr))
  local key = "format:" .. bufnr
  local timer = vim.defer_fn(function()
    show(key, "Formatting", #names > 0 and table.concat(names, ", ") or "LSP")
  end, DELAY_MS)
  conform.format({ async = true }, function(err)
    pcall(timer.stop, timer)
    hide(key)
    if err then
      vim.notify("Format failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

return M
