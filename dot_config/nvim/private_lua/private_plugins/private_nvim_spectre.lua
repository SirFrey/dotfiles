-- nvim-spectre is archived; replaced by grug-far.nvim
return {
  "MagicDuck/grug-far.nvim",
  cmd = "GrugFar",
  keys = {
    {
      "<leader>S",
      function()
        require("grug-far").toggle_instance({ instanceName = "far" })
      end,
      desc = "Toggle search & replace (grug-far)",
    },
    {
      "<leader>sw",
      function()
        require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
      end,
      desc = "Search current word",
    },
    {
      "<leader>sw",
      mode = "v",
      function()
        require("grug-far").with_visual_selection()
      end,
      desc = "Search selection",
    },
    {
      "<leader>sp",
      function()
        require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
      end,
      desc = "Search in current file",
    },
  },
  opts = {},
}
