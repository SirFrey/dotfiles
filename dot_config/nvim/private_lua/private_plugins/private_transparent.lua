return {
  "xiyaowong/transparent.nvim",
  -- load after all other plugins
  -- so that it can clear their highlights
  event = "VeryLazy",
  config = function()
    -- Optional, you don't have to run setup.
    require("transparent").setup({
      -- table: default groups
      groups = {
        "Normal",
        "NormalNC",
        "NormalFloat",
        "Comment",
        "Constant",
        "Special",
        "Identifier",
        "Statement",
        "PreProc",
        "Type",
        "Underlined",
        "Todo",
        "String",
        "Function",
        "Conditional",
        "Repeat",
        "Operator",
        "Structure",
        "LineNr",
        "NonText",
        "SignColumn",
        "CursorLine",
        "CursorLineNr",
        "StatusLine",
        "StatusLineNC",
        "EndOfBuffer",
      },
      -- table: additional groups that should be cleared
      extra_groups = { "NormalFloat" },
      -- table: groups you don't want to clear
      exclude_groups = {},
      -- function: code to be executed after highlight groups are cleared
      -- Also the user event "TransparentClear" will be triggered
      on_clear = function() end,
    })
    -- Clear specific groups
    require("transparent").clear_prefix("Telescope")
    -- Noice
    require("transparent").clear_prefix("Noice")
  end,
}
