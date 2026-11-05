return {
  "vuki656/package-info.nvim",
  dependencies = "MunifTanjim/nui.nvim",
  -- its BufEnter autocmds (auto-show versions) must exist before package.json is entered
  event = { "BufReadPre package.json", "BufNewFile package.json" },
  config = function()
    require("package-info").setup()
  end,
}
