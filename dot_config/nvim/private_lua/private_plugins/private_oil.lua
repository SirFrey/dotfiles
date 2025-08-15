return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  lazy = false,
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
  },
  opts = {
    view_options = {
      show_hidden = true,
    },
    keymaps = {
      ["<C-l>"] = false,
      ["gr"] = "actions.refresh",
      ["<C-h>"] = false,
      ["<C-a>"] = { "actions.select", opts = { horizontal = true } },
    },
  },
  -- Optional dependencies
  dependencies = { "nvim-tree/nvim-web-devicons" },
}
