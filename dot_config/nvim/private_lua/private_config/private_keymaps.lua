-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Netrw: file explorer" })
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
  pattern = { "text", "markdown" },
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
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, { desc = "Diagnostic: float" })
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, { desc = "Diagnostics: send to loclist" })

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    -- NOTE: gd (definition) and K (hover) are built-in defaults in Neovim 0.11
    local function bufmap(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    bufmap("i", "<C-h>", vim.lsp.buf.signature_help, "LSP: signature help")
    bufmap("n", "<space>wa", vim.lsp.buf.add_workspace_folder, "LSP: add workspace folder")
    bufmap("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, "LSP: remove workspace folder")
    bufmap("n", "<space>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "LSP: list workspace folders")
    bufmap("n", "<space>rn", vim.lsp.buf.rename, "LSP: rename")
    bufmap({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, "LSP: code action")
    -- grr = references, grn = rename, gra = code action, gri = implementation,
    -- grt = type definition, grx = codelens are all built-in since 0.11/0.12
    bufmap("n", "<space>f", function()
      require("conform").format({ async = true })
    end, "Format buffer")
    -- gf/gF -> LSP definition so imports with aliases (@/) and missing extensions resolve correctly
    bufmap("n", "gf", vim.lsp.buf.definition, "LSP: go to definition")
    bufmap("n", "gF", vim.lsp.buf.definition, "LSP: go to definition")
  end,
})
-- Quick TS LSP swap: :UseTsgo / :UseTsLs
vim.api.nvim_create_user_command("UseTsgo", function()
  vim.lsp.enable("ts_ls", false)
  vim.lsp.enable("tsgo")
end, {})
vim.api.nvim_create_user_command("UseTsLs", function()
  vim.lsp.enable("tsgo", false)
  vim.lsp.enable("ts_ls")
end, {})

--  e.g. ~/.local/share/chezmoi/*
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { vim.fn.expand("~") .. "/.local/share/chezmoi/*" },
    callback = function(ev)
        local bufnr = ev.buf
        local edit_watch = function()
            require("chezmoi.commands.__edit").watch(bufnr)
        end
        vim.schedule(edit_watch)
    end,
})

-- package.json
-- -- Show dependency versions
vim.keymap.set({ "n" }, "<LEADER>ns", require("package-info").show, { silent = true, noremap = true })

-- Hide dependency versions
vim.keymap.set({ "n" }, "<LEADER>nc", require("package-info").hide, { silent = true, noremap = true })

-- Toggle dependency versions
vim.keymap.set({ "n" }, "<LEADER>nt", require("package-info").toggle, { silent = true, noremap = true })

-- Update dependency on the line
vim.keymap.set({ "n" }, "<LEADER>nu", require("package-info").update, { silent = true, noremap = true })

-- Delete dependency on the line
vim.keymap.set({ "n" }, "<LEADER>nd", require("package-info").delete, { silent = true, noremap = true })

-- Install a new dependency
vim.keymap.set({ "n" }, "<LEADER>ni", require("package-info").install, { silent = true, noremap = true })

-- Install a different dependency version
vim.keymap.set({ "n" }, "<LEADER>np", require("package-info").change_version, { silent = true, noremap = true })
