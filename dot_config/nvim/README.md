# Moises's Neovim config

Built on [lazy.nvim](https://github.com/folke/lazy.nvim) — **not** LazyVim. Plugin specs live one-per-file under `lua/plugins/`.

## Structure

```
init.lua                 entry point
lua/config/
  options.lua            vim.opt + globals
  keymaps.lua            non-LSP keymaps
  lazy.lua               bootstrap + lazy.setup
lua/plugins/             one file per plugin spec
lazy-lock.json           pinned plugin versions
scripts/check-deps.sh    external dep probe (Linux/macOS/WSL)
scripts/check-deps.ps1   external dep probe (Windows / PowerShell)
stylua.toml              lua formatter config
```

## Install

```sh
git clone <this repo> ~/.config/nvim     # or: chezmoi apply (this repo is chezmoi-managed)
./scripts/check-deps.sh                  # verify external binaries (Linux/macOS/WSL)
pwsh ./scripts/check-deps.ps1            # verify external binaries (Windows)
nvim                                     # lazy.nvim auto-installs plugins on first launch
```

Inside Neovim on first launch:
- `lazy.nvim` syncs plugins automatically.
- `mason.nvim` + `mason-tool-installer` auto-install the LSP servers and formatters listed below — run `:Mason` to watch progress, `:checkhealth` to verify.

## External dependencies

The dep-check script (`./scripts/check-deps.sh`) prints OK/MISSING for each. Exit code = number of missing **required** deps.

### Required

| Tool | Used for | Install |
|---|---|---|
| `git` | lazy.nvim plugin clone, gitsigns, harpoon | `apt install git` / `brew install git` |
| `rg` (ripgrep) | telescope find_files + live_grep | `apt install ripgrep` / `brew install ripgrep` |
| `make` | build step for telescope-fzf-native, LuaSnip jsregexp | `apt install build-essential` / `brew install make` |
| C compiler (`cc`/`gcc`/`clang`) | treesitter parser builds | `apt install build-essential` / Xcode CLT |
| `node` | runtime for Mason-installed JS LSPs/formatters | mise / fnm / `apt install nodejs` |
| `tmux` | claudecode external terminal provider, vim-tmux-navigator | `apt install tmux` / `brew install tmux` |

### Recommended

| Tool | Used for | Install |
|---|---|---|
| `fd` | telescope auto-detects, faster file listing | `apt install fd-find` (binary is `fdfind` — symlink as `fd` for telescope) / `brew install fd` |
| `fzf` | not yet wired (telescope uses fzf-native in-process) | `apt install fzf` / `brew install fzf` |
| `lazygit` | community-standard git TUI | https://github.com/jesseduffield/lazygit |

### Optional (config has fallbacks)

| Tool | Used for | Install |
|---|---|---|
| `tsgo` | TypeScript 7 native LSP — falls back to `ts_ls` | `pnpm add -g @typescript/native-preview` |
| `tmux-sessionizer` | `<C-f>` keybind shells out | custom user script |

### Mason auto-installs (no manual action)

Wired in `lua/plugins/lsp.lua`. First Neovim launch triggers install.

- **LSPs** (mason-lspconfig): astro, bashls, cssls, gh_actions_ls, jsonls, lua_ls, pylsp, pyright, rust_analyzer, tailwindcss, ts_ls, yamlls
- **Tools** (mason-tool-installer): prettier, prettierd, stylua, isort, black, pylint, eslint_d

## Useful commands

| Command | Purpose |
|---|---|
| `:Lazy sync` | install / update plugins |
| `:Lazy profile` | startup time inspection |
| `:Mason` | inspect / install LSPs and tools |
| `:checkhealth` | full health report |
| `:UseTsgo` / `:UseTsLs` | swap TypeScript LSP at runtime |
| `:ConformInfo` | active formatter chain for current buffer |
| `:Trouble diagnostics` | diagnostic list |
| `./scripts/check-deps.sh` | external binary probe (Linux/macOS/WSL) |
| `pwsh ./scripts/check-deps.ps1` | external binary probe (Windows) |

## Notes

- This config is chezmoi-managed — edit the chezmoi source, never the live `~/.config/nvim` files directly.
- Contributor / formatting guidelines: see `AGENTS.md`.
- Lua formatting: `stylua .` (rules in `stylua.toml`).
