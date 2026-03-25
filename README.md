# Dotfiles

Managed with [chezmoi](https://chezmoi.io). Config lives in `~/.config/chezmoi/chezmoi.toml`.

> **Note:** `autoCommit` and `autoPush` are enabled — any `chezmoi add` or edit will commit and push to GitHub automatically.

---

## Setup on a new machine

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply SirFrey/dotfiles
```

Then restore secrets manually:

```bash
mkdir -p ~/.secrets && chmod 700 ~/.secrets
# Recreate ~/.secrets/opencode with your API keys
# See: Secrets section below
```

---

## Daily commands

### Add or update a file

```bash
chezmoi add ~/.zshrc
chezmoi add ~/.config/nvim/lua/plugins/harpoon.lua
```

For files with sensitive data, use env var substitution in the file (`{env:VAR}`) before adding — never add raw secrets.

### Edit a managed file

```bash
# Opens the source file in $EDITOR, applies on save
chezmoi edit ~/.zshrc

# Apply changes from source to home dir
chezmoi apply
```

### Remove a file from chezmoi tracking

```bash
chezmoi forget ~/.config/some/file
```

This stops tracking the file but does NOT delete it from your home directory.

### Check what's changed

```bash
# Files with pending changes
chezmoi status

# Full diff between source and home
chezmoi diff

# List all managed files
chezmoi managed
```

### See what chezmoi would do before applying

```bash
chezmoi apply --dry-run --verbose
```

---

## Git operations

Since autoPush is on, most git operations happen automatically. For manual control:

```bash
# Push manually
chezmoi git push

# Check git status of the source repo
chezmoi git status

# View commit log
chezmoi git log -- --oneline

# Open the source directory directly
cd $(chezmoi source-path)
```

---

## Secrets

Secrets are stored in `~/.secrets/opencode` (never committed) and loaded into the shell via `.zshrc`:

```zsh
[ -f ~/.secrets/opencode ] && set -a && source ~/.secrets/opencode && set +a
```

`opencode.json` references them with `{env:VAR_NAME}` — safe to commit, meaningless without the secrets file.

**Variables in `~/.secrets/opencode`:**

| Variable | Used by |
|---|---|
| `N8N_API_KEY` | n8n MCP server |
| `SLACK_MCP_TOKEN` | Slack MCP server |
| `CONTEXT7_KEY` | Context7 MCP server |
| `ZOHO_MCP_KEY` | Zoho MCP URL |
| `PLAYWRIGHT_TOKEN` | Playwright MCP extension |
| `GITLAB_OAUTH_CLIENT_ID` | GitLab MCP server |
| `GITLAB_OAUTH_CLIENT_SECRET` | GitLab MCP server |

Never run `chezmoi add ~/.secrets/opencode`. The `.chezmoiignore` blocks it, but double-check if you add new ignore rules.

---

## File naming in the source directory

chezmoi uses prefixes to encode metadata:

| Prefix | Meaning |
|---|---|
| `dot_` | Maps to `.` (e.g. `dot_zshrc` → `.zshrc`) |
| `private_` | Sets file permissions to `600` |
| `readonly_` | Sets file permissions to `444` |
| `executable_` | Sets file permissions to `755` |
| `_` suffix (dir) | `exact_` prefix removes unmanaged files in that dir |
| `.tmpl` extension | Treated as a Go template (supports `{{ .variable }}`) |

---

## Troubleshooting

### Changes not applying after edit

chezmoi source and home are out of sync. Run:

```bash
chezmoi diff        # see what's different
chezmoi apply       # apply source → home
```

If you edited the home file directly instead of the source:

```bash
chezmoi add ~/.zshrc    # re-add to sync source with home
```

### `chezmoi apply` overwrites changes I made directly

Always edit through chezmoi:

```bash
chezmoi edit ~/.zshrc   # correct way
```

If you edited directly and don't want to lose it:

```bash
chezmoi merge ~/.zshrc  # opens 3-way merge
```

### autoPush failing with secret scanning error

GitHub blocked a push because a secret was detected. To fix:

```bash
# Remove the offending file from the last commit
git -C ~/.local/share/chezmoi rm <file>

# If the commit only had that file, drop it entirely
git -C ~/.local/share/chezmoi reset HEAD^

# Add to .chezmoiignore so it never happens again
echo ".config/path/to/file" >> ~/.local/share/chezmoi/.chezmoiignore

# Force push to overwrite remote
git -C ~/.local/share/chezmoi push --force
```

Then rotate the exposed secret immediately.

### File shows as modified but nothing changed

Usually a line ending or permission issue. Check:

```bash
chezmoi diff ~/.zshrc
```

If it's permissions:

```bash
# Add private_ prefix in source if file should be 600
chezmoi forget ~/.zshrc
mv ~/.local/share/chezmoi/dot_zshrc ~/.local/share/chezmoi/private_dot_zshrc
chezmoi apply
```

### Template variables not resolving

Check your data is in `~/.config/chezmoi/chezmoi.toml` under `[data]`:

```toml
[data]
    email = "you@example.com"
```

Test rendering:

```bash
chezmoi execute-template '{{ .email }}'
```

### Undo the last apply

chezmoi doesn't have a built-in undo, but since autoPush is on the git history is your safety net:

```bash
# See recent commits
chezmoi git log -- --oneline

# Revert a specific file to a previous commit
git -C ~/.local/share/chezmoi checkout <commit-hash> -- <source-file>
chezmoi apply
```

---

## .chezmoiignore

Files and patterns excluded from chezmoi tracking:

```
.secrets/
.config/opencode/antigravity-accounts.json
.config/opencode/node_modules/
.config/opencode/bun.lock
.config/opencode/package.json
```

To add more:

```bash
echo ".config/some/file" >> ~/.local/share/chezmoi/.chezmoiignore
```
