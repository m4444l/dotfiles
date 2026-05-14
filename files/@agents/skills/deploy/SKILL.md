---
name: deploy
description: Deploy an app via its deploy script with git safety checks. Use whenever the user asks to deploy an app, push something to production, or simply says "deploy". Make sure to use this skill any time deployment is mentioned, even if the user doesn't reference a specific script — it handles worktree safety, the main-branch switch, and unpushed-commit checks before invoking the project's deploy script.
---

# Deploy

You are deploying an app. Deployment is invoked via the project's deploy script (`bin/deploy` or `./deploy`), but several git safety checks must happen **before** that script runs. The order below matters — do not skip ahead.

## 1. Worktree check (always first)

Never run the deploy script from inside a git worktree. The deploy script does things like switching branches and stashing — that's safe in the primary checkout but disruptive in a secondary worktree, and it can leave the worktree in an unexpected state.

Detect the situation by comparing the per-worktree git dir with the common one:

```sh
git rev-parse --git-dir
git rev-parse --git-common-dir
```

If those two differ, you're in a secondary worktree. Find the primary checkout and switch to it before doing anything else:

```sh
git worktree list
```

The first entry in `git worktree list` is the primary checkout (the repo's main working tree). All subsequent commands in this skill — including the deploy script itself — must run with that path as the working directory. Use `cd <primary-path>` (or pass `cwd:` to your shell tool) and keep using it for the rest of the run. Do not deploy from the secondary worktree under any circumstances.

If the primary checkout is currently on a branch other than `main`, stop and report. The deploy script expects to start from `main`.

## 2. Locate the deploy script

From the primary checkout, look for the deploy script in this order:

1. `bin/deploy`
2. `./deploy`

If neither exists (or exists but is not executable), abort and report — this app does not have a recognized deploy script and you should not improvise one.

Remember which path you found; you will invoke it verbatim at the end.

## 3. Unpushed commits on main

Make sure local `main` is in sync with `origin/main` before deploying. The deploy script assumes pushing `main` to origin will succeed, and won't recover gracefully if it can't.

```sh
git fetch origin
git rev-parse main
git rev-parse origin/main
git log --oneline origin/main..main   # commits on local main not yet on origin
git log --oneline main..origin/main   # commits on origin not yet on local main
```

Decide based on those two logs:

- **Both empty:** local `main` and `origin/main` are equal. Continue.
- **Only `origin/main..main` non-empty:** local `main` is ahead. Push it: `git push origin main`. Then continue.
- **Only `main..origin/main` non-empty:** local `main` is behind. Fast-forward: `git pull --ff-only origin main`. Then continue.
- **Both non-empty:** branches have diverged. Abort and report — do not auto-rebase, do not force-push. The user needs to resolve this before deploying.

If `git push origin main` is rejected for any reason (non-fast-forward, hook rejection, auth, etc.), abort and report. Do not retry with `--force`.

## 4. Local uncommitted changes are fine

Do not stash, commit, or otherwise touch uncommitted changes in the working tree. The deploy script handles this itself — it stashes before deploying and pops the stash afterwards. Leave them alone.

## 5. Run the deploy script

From the primary checkout, run whichever script you found in step 2 (`bin/deploy` or `./deploy`). Stream its output to the user. If it exits non-zero, report the failure — don't try to clean up after it; the script's own stash-pop step is responsible for that.

## Report

When the deploy script finishes successfully, report briefly:

- Which script was run (`bin/deploy` or `./deploy`)
- The primary checkout path it ran from
- The commit SHA on `main` that was deployed
