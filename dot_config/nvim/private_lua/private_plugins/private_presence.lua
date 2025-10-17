return {
  "vyfor/cord.nvim",
  event = "VeryLazy",
  build = ":Cord update",
  config = function()
    require("cord").setup({
      editor = {
        tooltip = "Nice Editor",
      },
      idle = {
        timeout = 600000,
        details = "Away From You",
      },
      text = {
        editing = function(opts)
          return "Editing " .. opts.filename
        end, -- or use a string value like 'Editing a file' if you don't want it to be dynamic
        -- etc ...
      },
      log_level = "trace", -- one of 'trace', 'debug', 'info', 'warn', 'error'
      advanced = {
        server = {
          pipe_path = "/tmp/discord-ipc-0",
        },
      },
    })
  end,
  -- opts = {}
  --
}
