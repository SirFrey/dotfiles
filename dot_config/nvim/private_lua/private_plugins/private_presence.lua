return {
  "vyfor/cord.nvim",
  build = ":Cord update",
  event = "VeryLazy",
  config = function()
    require("cord").setup({
     -- log_level = "trace", -- one of 'trace', 'debug', 'info', 'warn', 'error'
     -- advanced = {
     --   server = {
     --     pipe_path = "/tmp/discord-ipc-0",
     --   },
     -- },
    })
  end,
}
