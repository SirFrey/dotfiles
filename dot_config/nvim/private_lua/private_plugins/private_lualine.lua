return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  config = function()
    -- chezmoi-managed indicator, backed by the shared lookup module.
    local cm = require('chezmoi_managed')

    local function chezmoi_managed()
      return cm.is_managed(vim.fn.expand('%:p')) and ' chezmoi' or ''
    end

    require("lualine").setup({
      options = {
        section_separators = '',
        component_separators = ''
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'diagnostics' },
        lualine_c = {
          'filename',
          { chezmoi_managed, color = { fg = '#8aadf4', gui = 'bold' } },
        },
        lualine_x = { 'encoding' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
      },
      inactive_sections = {
        lualine_a = {},
        lualine_c = { 'filename' },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
      }
    })
  end
}
