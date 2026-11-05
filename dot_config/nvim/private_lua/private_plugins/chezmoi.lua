return {
  "xvzc/chezmoi.nvim",
  event = "User IdleLoad", -- first pause after startup (lua/idle.lua)
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("chezmoi").setup({})
  end,
}

