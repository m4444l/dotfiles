# AGENTS.md

Notes for agents (and humans) working on this dotfiles repo.

## Repo layout

- `files/` — every file/directory here is symlinked into `$HOME` as `.<name>` by `link.rb`. Subdirectories nest (e.g. `files/config/git/allowed_signers` becomes `~/.config/git/allowed_signers`).
- `link.rb` — Thor script. `./link.rb` to create missing symlinks, `./link.rb --force` to repoint existing ones, `./link.rb --dry-run` to preview. Requires Ruby ≥ 3.0; the shebang resolves to system ruby 2.6, so invoke as `mise exec -- ruby ./link.rb`.

## Shell setup overview

Goals:

1. **Interactive shells** activate mise with hooks (`mise activate zsh|bash`) so tool versions follow `.mise.toml` per directory. No shims on PATH.
2. **Non-interactive shells** activate mise with shims (`mise activate --shims`) so scripts/cron/GUI launchers resolve tools through `.mise.toml` at exec time.
3. mise's resolved paths must sit ahead of `/usr/bin` so e.g. `ruby` resolves to mise's ruby, not the system 2.6.
4. Homebrew detection is centralized in one helper (`activate_brew`) so adding install locations only requires one edit.

## File responsibilities

| File | When sourced | What it does |
|---|---|---|
| `files/shell-helpers.sh` | sourced explicitly by other files | Defines `source_if_exists`, `select_editor`, `path_prepend_if_exists`, `add_common_dirs_to_path`, `activate_brew`. POSIX-compatible function bodies (no `[[ ]]`) so bash/zsh both parse cleanly. |
| `files/profile` | sourced by `.zprofile` and `.bash_profile` (login shells only) | Exports `BASH_ENV`. Runs `activate_brew` for whichever shell sourced it. For bash also runs `mise activate bash --shims` (zsh handles its own mise in `.zshenv`/`.zshrc`). Assumes the sourcing shell is zsh or bash — no POSIX-sh branch. |
| `files/zprofile` | zsh login shells | One-liner that sources `~/.profile`. |
| `files/bash_profile` | bash login shells | Sources `~/.profile`, then sources `~/.bashrc` if interactive. |
| `files/zshenv` | every zsh invocation (login, non-login, interactive, non-interactive) | Always exports `BASH_ENV`. For **non-interactive** zsh only: sources helpers, calls `activate_brew zsh`, prepends `~/.local/bin`, then `eval "$(mise activate zsh --shims)"`. Interactive zsh skips the block — `.zshrc` will set it up properly. |
| `files/zshrc` | interactive zsh | Helpers + `add_common_dirs_to_path` + `eval "$(mise activate zsh)"` (hooks). |
| `files/bash_env` | non-interactive bash, when `BASH_ENV` points here | Sources helpers, calls `activate_brew bash`, prepends `~/.local/bin`, then `eval "$(mise activate bash --shims)"`. Interactive bash never sources this — bash ignores `BASH_ENV` for interactive shells. |
| `files/bashrc` | interactive bash | Helpers + `add_common_dirs_to_path` + `eval "$(mise activate bash)"` (hooks). |

## Sourcing order, per scenario

### Interactive login zsh (Terminal default on macOS)

1. `/etc/zshenv` (typically no-op)
2. `~/.zshenv` — exports `BASH_ENV`; interactive guard skips the mise block
3. `/etc/zprofile` — runs `/usr/libexec/path_helper` (builds PATH from `/etc/paths` + `/etc/paths.d/*`, appends inherited PATH)
4. `~/.zprofile` → `~/.profile` → `activate_brew zsh`
5. `/etc/zshrc`
6. `~/.zshrc` — `add_common_dirs_to_path`, `mise activate zsh` (hooks)

PATH front: `mise-installs → ~/.local/bin & friends → /opt/homebrew/bin → path_helper output (incl. /usr/bin)`. mise wins. No shims on PATH.

### Non-interactive zsh (script / cron with `#!/bin/zsh`)

1. `~/.zshenv` — exports `BASH_ENV`; runs the non-interactive block: brew, `~/.local/bin`, mise shims.

Nothing else fires. Shims at the front. mise wins.

### Interactive login bash

1. `~/.bash_profile` → `~/.profile` → exports `BASH_ENV`, `activate_brew bash`, `mise activate bash --shims`
2. `~/.bash_profile` → `~/.bashrc` → helpers, `add_common_dirs_to_path`, `mise activate bash` (hooks)

Both shims and hooks are on PATH. Hooks-based tool paths sit in front, so they win — but unlike zsh, shims linger. Acceptable tradeoff; not worth fixing.

### Non-interactive bash (script / `bash -c …`)

Only runs if `BASH_ENV` is set in the environment. Sources `~/.bash_env`: brew, `~/.local/bin`, mise shims.

`BASH_ENV` propagation:
- Any zsh sets `BASH_ENV` via `~/.zshenv` — so any bash spawned from zsh inherits it.
- Login bash sets `BASH_ENV` via `~/.profile` — so bash children of login bash inherit it.
- Bash spawned with no parent shell at all (cron, launchd plists) has no `BASH_ENV` and won't load mise. Fix by adding `BASH_ENV=$HOME/.bash_env` to the crontab / plist.

## Conventions / invariants worth preserving

- **Brew detection lives in `activate_brew`** in `shell-helpers.sh`. Don't reintroduce inline brew paths elsewhere.
- **`shell-helpers.sh` must stay free of `[[ ]]`** in function bodies. Functions are parsed when the file is sourced; the helpers are sourced from `profile`, which historically supported POSIX sh and might again. Use `case` for pattern matching.
- **`.zshenv` runs for every zsh invocation, including the prompt** — keep it fast. Avoid expensive operations there. The guard `[[ ! -o interactive ]]` skips the heavy work in interactive shells.
- **`profile` assumes its sourcer is bash or zsh.** If you ever source it from another shell, add a branch — don't quietly fall through.
- **`mise activate <shell>` (without `--shims`) installs a precmd hook.** It does run an initial PATH update at eval time, but tools that don't get the hook fired (e.g. `zsh -ic 'cmd'` with no prompt cycle) won't pick up directory-local `.mise.toml` versions. For scripts, prefer the shims path.
- **PATH ordering** is verified end-to-end in `env -i HOME=$HOME PATH=/usr/bin:/bin /bin/{zsh,bash} [-l -i] -c 'which ruby'`. If you change anything in the PATH chain, re-run those.

## Known imperfections (won't fix)

- `/opt/homebrew/bin` appears twice on PATH in interactive login shells — once from `/etc/paths.d/homebrew` (via `path_helper`) and once from `brew shellenv`. Harmless duplicate; removing it requires `sudo rm /etc/paths.d/homebrew` which is a system-wide change.
- GUI apps launched from launchd (Spotlight, Alfred, dock icons) don't source any shell rc files. They get launchd's PATH. Fix with `launchctl setenv PATH …` or `launchctl setenv BASH_ENV …` if needed; out of scope for these dotfiles.
- Non-interactive bash with no parent shell (cron, plists) doesn't get `BASH_ENV` unless the crontab/plist sets it. See "Non-interactive bash" above.

## Working in a worktree

Symlinks in `$HOME` may point either to `~/code/own/dotfiles/files/...` (canonical) or to a worktree under `~/.superset/worktrees/.../files/...` (if `./link.rb --force` was run from a worktree). After shipping a worktree and letting it be cleaned up, dangling symlinks need to be repointed by running `./link.rb --force` from `~/code/own/dotfiles`.
