return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      {
        "<leader>?",
        function()
          require("telescope.builtin").oldfiles()
        end,
        desc = "Telescope: Recent files",
      },
      {
        "<leader><space>",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Telescope: Buffers",
      },
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files()
        end,
        desc = "Telescope: Files",
      },
      {
        "<leader>fs",
        function()
          require("telescope.builtin").git_files()
        end,
        desc = "Telescope: Git files",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Telescope: Live grep",
      },
      {
        "<leader>ws",
        function()
          require("telescope.builtin").grep_string()
        end,
        desc = "Telescope: Word grep",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Telescope: Buffers",
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "Telescope: Help",
      },
      {
        "<leader>fk",
        function()
          require("telescope.builtin").keymaps()
        end,
        desc = "Telescope: Keymaps",
      },
      {
        "<leader>cz",
        function()
          require("telescope").extensions.chezmoi.find_files()
        end,
        desc = "Telescope: Chezmoi files",
      },
      {
        "<leader>fc",
        function()
          require("telescope").extensions.chezmoi.find_files({
            targets = vim.fn.stdpath("config"),
            args = {
              "--path-style", "absolute",
              "--include", "files",
              "--exclude", "externals",
            },
          })
        end,
        desc = "Telescope: Chezmoi config",
      },
    },
    config = function()
      require("telescope").setup({
        pickers = {
          find_files = {
            follow = true,
          },
        },
        defaults = {
          file_ignore_patterns = { ".git" },
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "-L",
          },
          find_command = { "rg", "--files", "--hidden", "-L" },
        },
      })
      local telescope = require("telescope")

      telescope.load_extension("chezmoi")
    end,
  },
}
