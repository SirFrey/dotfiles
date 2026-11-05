-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
-- netrw is disabled (oil replaces it), so :Ex no longer exists
vim.keymap.set("n", "<leader>pv", "<cmd>Oil<cr>", { desc = "Oil: file explorer" })
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste over (keep yank)" })
vim.keymap.set("n", "Q", "<nop>", { desc = "Disable Ex mode" })

-- Move through pages
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down + center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up + center" })

-- Remap for dealing with word wrap only in specific file types
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "markdown", "claudeprompt" },
  callback = function()
    vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
    vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
  end,
})

vim.keymap.set("n", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })

vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "tmux sessionizer" })

vim.keymap.set("v", "<leader>d", '"_d', { desc = "Delete to black hole" })
vim.keymap.set("n", "<leader>d", '"_d', { desc = "Delete to black hole" })

vim.keymap.set("n", "]q", "<cmd>cnext<CR>zz", { desc = "Quickfix: next" })
vim.keymap.set("n", "[q", "<cmd>cprev<CR>zz", { desc = "Quickfix: prev" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Loclist: next" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Loclist: prev" })

-- Jump list navigation
vim.keymap.set("n", "<leader>o", "<C-o>", { desc = "Jump list: back" })
vim.keymap.set("n", "<leader>i", "<C-i>", { desc = "Jump list: forward" })

vim.keymap.set("n", "<leader>sb", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Substitute word in buffer" })

vim.keymap.set("n", "<leader>mr", "<cmd>CellularAutomaton make_it_rain<CR>", { desc = "Make it rain" })

vim.keymap.set({ "i" }, "<C-K>", function()
  require("luasnip").expand()
end, { silent = true, desc = "Luasnip: expand" })
vim.keymap.set({ "i", "s" }, "<C-L>", function()
  require("luasnip").jump(1)
end, { silent = true, desc = "Luasnip: jump forward" })
vim.keymap.set({ "i", "s" }, "<C-J>", function()
  require("luasnip").jump(-1)
end, { silent = true, desc = "Luasnip: jump back" })

vim.keymap.set({ "i", "s" }, "<C-E>", function()
  local ls_ok, ls = pcall(require, "luasnip")
  if ls_ok and ls.choice_active() then
    ls.change_choice(1)
  end
end, { silent = true, desc = "Luasnip: change choice" })

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set("n", "<space>e", function() vim.diagnostic.open_float() end, { desc = "Diagnostic: float" })
vim.keymap.set("n", "<space>q", function() vim.diagnostic.setloclist() end, { desc = "Diagnostics: send to loclist" })

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    -- K, gd, gf/gF and the gr* keys are set globally below (they wait for the server)
    local function bufmap(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    bufmap("i", "<C-h>", vim.lsp.buf.signature_help, "LSP: signature help")
    bufmap("n", "<space>wa", vim.lsp.buf.add_workspace_folder, "LSP: add workspace folder")
    bufmap("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, "LSP: remove workspace folder")
    bufmap("n", "<space>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "LSP: list workspace folders")
    bufmap("v", "<space>ca", vim.lsp.buf.code_action, "LSP: code action")
    -- grr = references, grn = rename, gra = code action, gri = implementation,
    -- grt = type definition, grx = codelens are all built-in since 0.11/0.12
    bufmap("n", "<space>f", function()
      require("lsp_feedback").format()
    end, "Format buffer")
  end,
})

-- LSP keys that also work before the server has attached: they wait for it
-- with a visible message (lua/lsp_feedback.lua) instead of failing, or, for K,
-- running :Man on a TypeScript symbol. Slow replies show a spinner too.
-- run a built-in normal-mode key; report its error as one line, not a Lua traceback
local function normal(keys)
  return function()
    local ok, err = pcall(vim.cmd, "normal! " .. keys)
    if not ok then
      err = tostring(err)
      vim.notify(err:match("Vim:(.*)$") or err:match("(E%d+:.*)$") or err, vim.log.levels.WARN)
    end
  end
end
local function lsp_key(lhs, method, action, desc, fallback)
  vim.keymap.set("n", lhs, function()
    require("lsp_feedback").with_client(method, action, fallback)
  end, { desc = desc })
end
-- no language server for this file: plain K (keywordprg, e.g. :help in vim files)
lsp_key("K", "textDocument/hover", function() vim.lsp.buf.hover() end, "LSP: hover", normal("K"))
lsp_key("grr", "textDocument/references", function() vim.lsp.buf.references() end, "LSP: references")
lsp_key("gri", "textDocument/implementation", function() vim.lsp.buf.implementation() end, "LSP: implementation")
lsp_key("grt", "textDocument/typeDefinition", function() vim.lsp.buf.type_definition() end, "LSP: type definition")
lsp_key("grn", "textDocument/rename", function() vim.lsp.buf.rename() end, "LSP: rename")
lsp_key("gra", "textDocument/codeAction", function() vim.lsp.buf.code_action() end, "LSP: code action")
lsp_key("gO", "textDocument/documentSymbol", function() vim.lsp.buf.document_symbol() end, "LSP: document symbols")
lsp_key("<space>rn", "textDocument/rename", function() vim.lsp.buf.rename() end, "LSP: rename")
lsp_key("<space>ca", "textDocument/codeAction", function() vim.lsp.buf.code_action() end, "LSP: code action")
-- gf/gF -> LSP definition so imports with aliases (@/) and missing extensions resolve;
-- plain Vim gf/gF in files without a language server
lsp_key("gf", "textDocument/definition", function() vim.lsp.buf.definition() end, "LSP: go to definition", normal("gf"))
lsp_key("gF", "textDocument/definition", function() vim.lsp.buf.definition() end, "LSP: go to definition", normal("gF"))
-- gd: stock nvim keeps Vim's text-search "local declaration" even with an LSP attached
lsp_key("gd", "textDocument/definition", function() vim.lsp.buf.definition() end, "LSP: go to definition", normal("gd"))

-- gx (vim.ui.open): on WSL xdg-open takes a second or more to hand the URL to
-- Windows with nothing on screen meanwhile; show what's being opened until it has.
local ui_open = vim.ui.open
vim.ui.open = function(path, opt)
  local obj, err = ui_open(path, opt)
  if obj then
    local target = #path > 60 and (path:sub(1, 57) .. "...") or path
    require("lsp_feedback").until_done("Opening", target, function()
      return obj:is_closing()
    end)
  end
  return obj, err
end

-- Saving a file in the chezmoi source dir (~/.local/share/chezmoi/*) applies
-- it to its target. chezmoi.nvim's watch did this with blocking calls (a
-- freeze on open and on every save); this runs `chezmoi apply` in the
-- background with a spinner and reports the result.
local chezmoi_ignore = { "^run_onchange_", "^run_once_", "^run_after_", "^run_before_", "^%.chezmoi" }
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = vim.fn.expand("~") .. "/.local/share/chezmoi/*",
  callback = function(ev)
    local file = vim.api.nvim_buf_get_name(ev.buf)
    local name = vim.fn.fnamemodify(file, ":t")
    for _, pat in ipairs(chezmoi_ignore) do
      if name:match(pat) then
        return
      end
    end
    require("lsp_feedback").run("chezmoi apply", name, { "chezmoi", "apply", "--source-path", file }, {
      done_msg = "chezmoi: applied " .. name,
      -- files in the source dir that don't map to a target (README, .git, ...)
      quiet_error = function(stderr)
        return stderr:find("not in source state") ~= nil or stderr:find("not managed") ~= nil
      end,
      on_done = function()
        pcall(function()
          require("chezmoi_managed").refresh()
        end)
      end,
    })
  end,
})

-- package.json
-- -- Show dependency versions
vim.keymap.set({ "n" }, "<LEADER>ns", function() require("package-info").show() end, { silent = true, noremap = true })

-- Hide dependency versions
vim.keymap.set({ "n" }, "<LEADER>nc", function() require("package-info").hide() end, { silent = true, noremap = true })

-- Toggle dependency versions
vim.keymap.set({ "n" }, "<LEADER>nt", function() require("package-info").toggle() end, { silent = true, noremap = true })

-- Update dependency on the line
vim.keymap.set({ "n" }, "<LEADER>nu", function() require("package-info").update() end, { silent = true, noremap = true })

-- Delete dependency on the line
vim.keymap.set({ "n" }, "<LEADER>nd", function() require("package-info").delete() end, { silent = true, noremap = true })

-- Install a new dependency
vim.keymap.set({ "n" }, "<LEADER>ni", function() require("package-info").install() end, { silent = true, noremap = true })

-- Install a different dependency version
vim.keymap.set({ "n" }, "<LEADER>np", function() require("package-info").change_version() end, { silent = true, noremap = true })

-- Neocodium
vim.keymap.set("i", "<A-f>", function()
    require("neocodeium").accept()
end)
vim.keymap.set("i", "<A-w>", function()
    require("neocodeium").accept_word()
end)
vim.keymap.set("i", "<A-a>", function()
    require("neocodeium").accept_line()
end)
vim.keymap.set("i", "<A-e>", function()
    require("neocodeium").cycle_or_complete()
end)
vim.keymap.set("i", "<A-r>", function()
    require("neocodeium").cycle_or_complete(-1)
end)
vim.keymap.set("i", "<A-c>", function()
    require("neocodeium").clear()
end)
