return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
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
      -- Noise dirs that shouldn't appear in fuzzy results even though they're
      -- under hidden paths. Kept narrow: explicit caches and package stores,
      -- not all dotfiles. `.config`, `.ssh`, `.tmux`, etc. remain searchable.
      local noise_globs = {
        "!**/.git/**",
        "!**/.cache/**",
        "!**/.local/share/**",
        "!**/.local/state/**",
        "!**/.npm/**",
        "!**/.pnpm-store/**",
        "!**/.bun/install/cache/**",
        "!**/.cargo/registry/**",
        "!**/.cargo/git/**",
        "!**/.rustup/**",
        "!**/.mozilla/**",
        "!**/.vscode-server/**",
        "!**/.vscode-oss/**",
        "!**/node_modules/**",
        "!**/.next/**",
        "!**/dist/**",
        "!**/build/**",
        "!**/__pycache__/**",
      }

      local function with_globs(base)
        local args = vim.deepcopy(base)
        for _, g in ipairs(noise_globs) do
          table.insert(args, "--glob")
          table.insert(args, g)
        end
        return args
      end

      require("telescope").setup({
        pickers = {
          find_files = {
            follow = true,
            find_command = with_globs({ "rg", "--files", "--hidden", "-L" }),
          },
        },
        defaults = {
          file_ignore_patterns = { "%.git/", "node_modules/" },
          vimgrep_arguments = with_globs({
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "-L",
          }),
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })
      local telescope = require("telescope")

      telescope.load_extension("fzf")
      telescope.load_extension("chezmoi")
    end,
  },
}
