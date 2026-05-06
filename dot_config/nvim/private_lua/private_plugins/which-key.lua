return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    win = {
      no_overlap = false,
      height = { min = 4, max = 25 },
    },
    keys = {
      scroll_down = "<c-d>",
      scroll_up = "<c-u>",
    },
    spec = {
      -- Group names for leader prefixes
      { "<leader>f", group = "find/file" },
      { "<leader>?", group = "help/discovery" },
      { "<leader>w", group = "workspace" },
      { "<leader>x", group = "trouble" },
      { "<leader>c", group = "code/lsp" },
      { "<leader>s", group = "search/substitute" },
      { "<space>w", group = "lsp workspace" },

      -- Built-in window commands (<C-w>) — not vim.keymap.set, so document via spec
      { "<C-w>", group = "window" },
      { "<C-w>v", desc = "Split vertical" },
      { "<C-w>s", desc = "Split horizontal" },
      { "<C-w>q", desc = "Close window" },
      { "<C-w>c", desc = "Close window" },
      { "<C-w>o", desc = "Close other windows" },
      { "<C-w>=", desc = "Equalize sizes" },
      { "<C-w>_", desc = "Max height" },
      { "<C-w>|", desc = "Max width" },
      { "<C-w>h", desc = "Move to left window" },
      { "<C-w>j", desc = "Move to below window" },
      { "<C-w>k", desc = "Move to above window" },
      { "<C-w>l", desc = "Move to right window" },
      { "<C-w>H", desc = "Move window left" },
      { "<C-w>J", desc = "Move window down" },
      { "<C-w>K", desc = "Move window up" },
      { "<C-w>L", desc = "Move window right" },
      { "<C-w>r", desc = "Rotate windows" },
      { "<C-w>w", desc = "Cycle windows" },
      { "<C-w>p", desc = "Previous window" },
      { "<C-w>T", desc = "Move to new tab" },

      -- `g` prefix: go-to / extra
      { "g", group = "go to / extra" },
      { "gd", desc = "Go to definition" },
      { "gD", desc = "Go to declaration" },
      { "gi", desc = "Last insert position" },
      { "gv", desc = "Reselect last visual" },
      { "gf", desc = "Go to file under cursor" },
      { "gF", desc = "Go to file + line" },
      { "gg", desc = "Top of file" },
      { "gJ", desc = "Join (no spaces)" },
      { "gq", desc = "Format motion" },
      { "gu", desc = "Lowercase motion" },
      { "gU", desc = "Uppercase motion" },
      { "g~", desc = "Toggle case motion" },
      { "g;", desc = "Older change position" },
      { "g,", desc = "Newer change position" },
      { "g*", desc = "Search word (partial)" },
      { "g#", desc = "Search word back (partial)" },
      { "gx", desc = "Open URL/file under cursor" },
      { "gcc", desc = "Toggle line comment" },
      { "gc", desc = "Toggle comment motion" },

      -- `z` prefix: fold / view
      { "z", group = "fold / view" },
      { "zz", desc = "Center cursor line" },
      { "zt", desc = "Cursor line to top" },
      { "zb", desc = "Cursor line to bottom" },
      { "za", desc = "Toggle fold" },
      { "zo", desc = "Open fold" },
      { "zc", desc = "Close fold" },
      { "zR", desc = "Open all folds" },
      { "zM", desc = "Close all folds" },

      -- Bracket pairs (vim-unimpaired style)
      { "[", group = "previous" },
      { "]", group = "next" },
      { "[q", desc = "Quickfix prev" },
      { "]q", desc = "Quickfix next" },
      { "[d", desc = "Diagnostic prev" },
      { "]d", desc = "Diagnostic next" },
      { "[c", desc = "Git hunk prev" },
      { "]c", desc = "Git hunk next" },
      { "[h", desc = "Harpoon prev" },
      { "]h", desc = "Harpoon next" },
    },
  },
  keys = {
    {
      "<leader>?k",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Which-key: buffer-local",
    },
    {
      "<leader>?K",
      function()
        require("which-key").show({ global = true })
      end,
      desc = "Which-key: all keymaps",
    },
  },
}
