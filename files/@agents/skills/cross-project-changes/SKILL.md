---
name: cross-project-changes
description: Guidance for applying changes across multiple projects. Use when user wants to make changes across multiple projects or apps simultaneously.
---

# Cross-Project Changes

Follow these steps when applying changes across multiple projects.

## Step 1: Identify Target Projects

Determine which projects need the change:
- "all my projects", "all my apps", "all projects" or "all apps" means the following folders:
  - dasauge: ~/code/own/dasauge-app
  - funlocked: ~/code/own/funlocked-app
  - notetoself: ~/code/own/notetoself
  - spendex: ~/code/own/spendex
  - uplink: ~/code/own/uplink-app
  - m4l: ~/code/own/m4l
- If unsure, ask the user to specify the target projects
- When searching for files across projects using `ripgrep`, use `**/` globs to handle nested app roots (e.g., `**/find/this/file.rb`)

## Step 2: Determine the Changes

Identify what changes to apply:
- Check if the user described the changes in their prompt
- If they mentioned "changes from the last commit" or similar, inspect the last git commit in the current folder

## Step 3: Confirm Git Commit Preference

Before applying any changes, check if the user specified whether to commit changes to git:
- If the user explicitly said to commit or not commit, follow their instruction
- If not specified, ask the user whether they want changes committed to git in each project after applying

## Step 4: Apply Changes Using Parallel Subagents

Spawn one subagent per project using the Task tool to apply changes in parallel:
- Launch all subagents simultaneously in a single message (do NOT process projects sequentially)
- Each subagent receives:
  - The target project path
  - A clear description of the changes to apply
  - Whether to commit changes to git
  - Instructions to run relevant tests after applying changes
  - Instructions to report back: what changed, what was skipped, test results
- The implementation may differ between projects based on their structure
- If changes cannot be applied to a project, the subagent should skip it and report why

Each subagent must follow this workflow:
1. If committing: check for uncommitted changes or untracked files via `git status`. If any exist, run `git stash --include-untracked` before starting work.
2. Apply the changes and run relevant tests.
3. If committing: commit the changes, then run `git stash pop` if a stash was created in step 1.
4. If not committing: skip git stash/commit entirely.

## Step 5: Report Results

After all subagents complete:
- Summarize which projects were updated successfully
- List any projects that were skipped and why
- Mention any test failures or projects missing test coverage
- If changes were not committed, remind the user
