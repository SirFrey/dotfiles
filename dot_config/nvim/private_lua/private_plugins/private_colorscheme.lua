return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        float = {
          transparent = true, -- enables transparency on floating windows
        },
        transparent_background = true,
        show_end_of_buffer = true,
        -- Explicit list instead of auto_integrations, which scans every installed
        -- plugin at startup (~3ms). Same set it detected; add new plugins here.
        auto_integrations = false,
        integrations = {
          cmp = true, fidget = true, flash = true, gitsigns = true, grug_far = true, harpoon = true,
          lsp_trouble = true, mason = true, render_markdown = true, snacks = true, telescope = true, which_key = true,
        },
      })
      vim.cmd.colorscheme("catppuccin-frappe")
    end,
  },
}
