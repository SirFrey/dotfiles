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
      vim.keymap.set("n", "<leader>cz", telescope.extensions.chezmoi.find_files, {})

      -- You can also search a specific target directory and override arguments
      -- Here is an example with the default args
      vim.keymap.set("n", "<leader>fc", function()
        telescope.extensions.chezmoi.find_files({
          targets = vim.fn.stdpath("config"),
          -- This overrides the default arguments used with 'chezmoi list'
          args = {
            "--path-style",
            "absolute",
            "--include",
            "files",
            "--exclude",
            "externals",
          },
        })
      end, {})
    end,
  },
}
