-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("x", "<leader>p", '"_dP')
vim.keymap.set("n", "Q", "<nop>")

-- Move trough pages
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Remap for dealing with word wrap only in specific file types
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "markdown" },
  callback = function()
    vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
    vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
  end,
})

vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

vim.keymap.set("v", "<leader>d", '"_d')
vim.keymap.set("n", "<leader>d", '"_d')

vim.keymap.set("n", "<C-k", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>sb", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader>mr", "<cmd>CellularAutomaton make_it_rain<CR>")

-- See `:help telescope.builtin`
vim.keymap.set("n", "<leader>?", function() require("telescope.builtin").oldfiles() end, { desc = "[?] Find recently opened files" })
vim.keymap.set("n", "<leader><space>", function() require("telescope.builtin").buffers() end, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>ff", function() require("telescope.builtin").find_files() end, {})
vim.keymap.set("n", "<leader>fs", function() require("telescope.builtin").git_files() end, {})
vim.keymap.set("n", "<leader>fg", function() require("telescope.builtin").live_grep() end, {})
vim.keymap.set("n", "<leader>ws", function() require("telescope.builtin").grep_string() end, {})
vim.keymap.set("n", "<leader>fb", function() require("telescope.builtin").buffers() end, {})
vim.keymap.set("n", "<leader>fh", function() require("telescope.builtin").help_tags() end, {})

-- Harpoon
vim.keymap.set("n", "<leader>a", function() require("harpoon"):list():add() end)
vim.keymap.set("n", "<C-e>", function() local h=require("harpoon"); h.ui:toggle_quick_menu(h:list()) end)
vim.keymap.set("n", "<C-h>", function() require("harpoon"):list():select(1) end)
vim.keymap.set("n", "<C-t>", function() require("harpoon"):list():select(2) end)
vim.keymap.set("n", "<C-n>", function() require("harpoon"):list():select(3) end)
vim.keymap.set("n", "<C-s>", function() require("harpoon"):list():select(4) end)
-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<C-S-P>", function() require("harpoon"):list():prev() end)
vim.keymap.set("n", "<C-S-N>", function() require("harpoon"):list():next() end)
vim.keymap.set("n", "<C-i>", function() require("harpoon"):list():prev() end)
vim.keymap.set("n", "<C-o>", function() require("harpoon"):list():next() end)

vim.keymap.set({ "i" }, "<C-K>", function()
  require("luasnip").expand()
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-L>", function()
  require("luasnip").jump(1)
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-J>", function()
  require("luasnip").jump(-1)
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-E>", function()
  local ls_ok, ls = pcall(require, "luasnip")
  if ls_ok and ls.choice_active() then
    ls.change_choice(1)
  end
end, { silent = true })

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set("n", "<space>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<space>f", function()
      require("conform").format({ async = true })
    end, opts)
  end,
})
-- oil
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
-- spectre
vim.keymap.set("n", "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', {
  desc = "Toggle Spectre",
})
vim.keymap.set("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
  desc = "Search current word",
})
vim.keymap.set("v", "<leader>sw", '<esc><cmd>lua require("spectre").open_visual()<CR>', {
  desc = "Search current word",
})
vim.keymap.set("n", "<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
  desc = "Search on current file",
})

-- Copilot
-- when Ctrl + C is pressed, it will close the suggestion
vim.keymap.set("i", "<C-c>", function()
  require("copilot.suggestion").dismiss()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, false, true), "n", false)
end, {
  desc = "[copilot] dismiss suggestion",
  silent = true,
})

-- accept Copilot even if cmp is showing, and do NOT let cmp reopen afterward
vim.keymap.set("i", "<C-y>", function()
  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp then
    if cmp.visible() then
      cmp.abort()  -- close the menu and roll back any inline edits from the session
                   -- (use cmp.close() if you prefer not to roll back). 
    end
    vim.g.__cmp_suppress_once = true  -- stop auto popup on the next TextChangedI
  end

  local ok_cop, cop = pcall(require, "copilot.suggestion")
  if ok_cop and cop.is_visible() then
    cop.accept()  -- insert the ghost text as real text
  end

  -- allow cmp to resume after a short delay
  vim.defer_fn(function()
    vim.g.__cmp_suppress_once = false
  end, 120)  -- tweak the debounce (ms) if needed
end, {
  desc = "[copilot] accept suggestion and keep cmp closed",
  silent = true,
})
