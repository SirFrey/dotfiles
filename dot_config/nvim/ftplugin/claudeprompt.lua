vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = "nc"
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.spell = false
vim.diagnostic.enable(false, { bufnr = 0 })

local BANNER = "^# ─── Write your reply"
local TRUNCATED = "… (earlier output truncated)"

local function tail_lines(path, bytes)
  local f = io.open(path, "rb")
  if not f then
    return {}
  end
  local size = f:seek("end")
  f:seek("set", math.max(0, size - bytes))
  local data = f:read("*a")
  f:close()
  local lines = vim.split(data, "\n", { plain = true })
  if size > bytes then
    table.remove(lines, 1)
  end
  return lines
end

local function last_nonempty(lines, n)
  local out = {}
  for i = #lines, 1, -1 do
    local l = vim.trim(lines[i])
    if l ~= "" then
      table.insert(out, 1, l)
      if #out == n then
        break
      end
    end
  end
  return table.concat(out, "\n")
end

-- The env var is only a hint (it may belong to a parent session), so the
-- most recently written transcripts are always searched too.
local function transcripts()
  local dir = vim.fn.expand("~/.claude/projects")
  local files = {}
  local sid = vim.env.CLAUDE_CODE_SESSION_ID
  if sid and sid ~= "" then
    vim.list_extend(files, vim.fn.glob(dir .. "/*/" .. sid .. ".jsonl", false, true))
  end
  local recent = {}
  for _, p in ipairs(vim.fn.glob(dir .. "/*/*.jsonl", false, true)) do
    table.insert(recent, { path = p, mtime = vim.fn.getftime(p) })
  end
  table.sort(recent, function(a, b)
    return a.mtime > b.mtime
  end)
  for i = 1, math.min(5, #recent) do
    table.insert(files, recent[i].path)
  end
  return files
end

local function find_full_response(want)
  for _, path in ipairs(transcripts()) do
    local lines = tail_lines(path, 4 * 1024 * 1024)
    for i = #lines, 1, -1 do
      if lines[i]:find('"type":"assistant"', 1, true) then
        local ok, entry = pcall(vim.json.decode, lines[i])
        local content = ok and type(entry.message) == "table" and entry.message.content
        if type(content) == "table" then
          for _, block in ipairs(content) do
            if block.type == "text" and type(block.text) == "string" then
              local text = vim.split(block.text, "\n", { plain = true })
              if last_nonempty(text, 3) == want then
                return text
              end
            end
          end
        end
      end
    end
  end
end

-- Claude Code quotes only the last 50 lines of its response (hard-coded).
-- Everything above the banner is discarded on save, so swapping in the full
-- response from the session transcript can't leak into the reply.
local function expand_response(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local banner
  for i, l in ipairs(lines) do
    if l:find(BANNER) then
      banner = i
      break
    end
  end
  if not banner or lines[2] ~= "# " .. TRUNCATED then
    return
  end
  local quoted = {}
  for i = 3, banner - 1 do
    table.insert(quoted, (lines[i]:gsub("^# ?", "")))
  end
  local full = find_full_response(last_nonempty(quoted, 3))
  if not full then
    return
  end
  local prefixed = vim.tbl_map(function(l)
    return l == "" and "#" or "# " .. l
  end, full)
  vim.api.nvim_buf_set_lines(buf, 1, banner - 1, false, prefixed)
  vim.bo[buf].modified = false
end

vim.schedule(function()
  local buf = vim.api.nvim_get_current_buf()
  pcall(expand_response, buf)
  -- Start at the reply area instead of the top of the quoted response.
  local line = vim.fn.search(BANNER, "n")
  if line > 0 then
    vim.api.nvim_win_set_cursor(0, { math.min(line + 1, vim.fn.line("$")), 0 })
  end
end)
