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
      })
      vim.cmd.colorscheme("catppuccin-frappe")
    end,
  },
}
