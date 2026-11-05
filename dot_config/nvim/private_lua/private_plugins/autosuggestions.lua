-- add this to the file where you setup your other plugins:
return {
  "monkoose/neocodeium",
  event = "InsertEnter", -- server starts on first insert, not at startup
  config = function()
    local neocodeium = require("neocodeium")
    neocodeium.setup()
    vim.keymap.set("i", "<A-f>", neocodeium.accept)
  end,
}
