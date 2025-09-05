return {
  "xvzc/chezmoi.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("chezmoi").setup({})
  end,
}

