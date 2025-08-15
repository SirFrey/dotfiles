return {
  "theprimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { '<leader>a', function() require('harpoon'):list():add() end, desc = 'Harpoon: Add file' },
    { '<C-e>', function() local h=require('harpoon'); h.ui:toggle_quick_menu(h:list()) end, desc = 'Harpoon: Toggle menu' },
    { '<C-h>', function() require('harpoon'):list():select(1) end, desc = 'Harpoon: 1' },
    { '<C-t>', function() require('harpoon'):list():select(2) end, desc = 'Harpoon: 2' },
    { '<C-n>', function() require('harpoon'):list():select(3) end, desc = 'Harpoon: 3' },
    { '<C-s>', function() require('harpoon'):list():select(4) end, desc = 'Harpoon: 4' },
    { '<C-S-P>', function() require('harpoon'):list():prev() end, desc = 'Harpoon: Prev' },
    { '<C-S-N>', function() require('harpoon'):list():next() end, desc = 'Harpoon: Next' },
    { '<C-i>', function() require('harpoon'):list():prev() end, desc = 'Harpoon: Prev' },
    { '<C-o>', function() require('harpoon'):list():next() end, desc = 'Harpoon: Next' },
  },
  config = function()
    require("harpoon"):setup()
  end,
}
