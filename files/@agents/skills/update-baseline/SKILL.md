---
name: update-baseline
description: Update the Baseline gem in one or more owned apps, commit and push the result, then optionally deploy. Use this whenever the user says "update baseline in app X", "update baseline in all my apps", "update baseline everywhere", or asks to bump/refresh/upgrade Baseline in any app. This skill deliberately combines `cross-project-changes` for multi-app execution and `deploy` for the optional deployment follow-up.
---

# Update Baseline

Use this skill when the user wants Baseline updated in one app or across owned apps.

## Skills to use

Load and follow these skills as part of this workflow:

- `cross-project-changes` to identify and update the target apps in parallel.
- `deploy` only after the user explicitly confirms deployment.

Do not treat deployment as implied by the update request. Updating, committing, and pushing are part of this skill; deployment is a separate confirmation step.

## Target apps

Interpret the request like this:

- `update baseline in all my apps`, `update Baseline everywhere`, or similar means all apps known to `cross-project-changes`.
- `update baseline in app X` means only the named app. Use project shorthand from `AGENTS.md` when available.
- If the target app is ambiguous, ask a short clarifying question before changing anything.

## Update workflow

Use `cross-project-changes` for the actual app updates. Tell each project worker to:

1. Work in the target app checkout.
2. Check `git status --short` before changing anything.
3. Preserve unrelated local work using the `cross-project-changes` stash workflow.
4. Run:

   ```sh
   bundle update baseline
   ```

5. Run the app's relevant verification for a dependency update. Prefer existing binstubs when present, especially:

   ```sh
   bin/rails zeitwerk:check
   bin/rspec
   ```

   If no binstub exists, use the app's established fallback.

6. Commit the Baseline update in that app with a Conventional Commits message, usually:

   ```text
   chore(deps): update baseline
   ```

7. Push the app's current branch to its remote.
8. Report the commit SHA, branch, verification result, and any skipped or failed step.

For this skill, the user's request already implies committing and pushing. Do not ask whether to commit unless the user explicitly says not to commit or push.

If `bundle update baseline` changes no files in an app, do not create an empty commit. Report the app as already current.

## Deployment preview

After all targeted app updates finish, ask whether the successfully updated apps should be deployed.

Before asking, list what would be deployed for each successfully updated app. Determine the last deployment point from the latest `deploy` tag reachable from `main`, then list commits after it:

```sh
git fetch --tags origin
git describe --tags --match "deploy*" --abbrev=0 main
git log --oneline <last-deploy-tag>..main
```

If no `deploy*` tag exists, say that no deploy tag was found and list recent commits on `main` instead:

```sh
git log --oneline -20 main
```

Use a compact format:

```text
Deploy preview:
- app-name: last deploy <tag-or-not-found>
  <sha> <subject>
  <sha> <subject>
```

If an app was skipped, failed verification, failed commit, or failed push, do not offer it for deployment unless the user explicitly asks.

## Deployment

If the user confirms deployment, use the `deploy` skill for each confirmed app.

Deploy only the apps the user approves. If they approve "all", deploy every successfully updated app listed in the preview. Follow the `deploy` skill exactly for each app, including its worktree and unpushed-commit checks.

Report deployment results per app:

- deployed app
- script used
- checkout path
- deployed commit SHA
- failures or apps left undeployed
