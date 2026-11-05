return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "User IdleLoad", -- first pause after startup (lua/idle.lua)
  opts = {},
}
