---
name: commit
description: >-
  Create a git commit for the current worktree changes using Conventional
  Commits and this repo's git rules. Use when the user runs /commit or asks
  to commit.
disable-model-invocation: true
---

# Commit

Create a git commit now. Do not ask for confirmation unless there is nothing to commit or secrets are involved.

## How the user invokes this

- Slash: `/commit` in Agent chat
- Invoke with slash **`/commit`** in the **current** Agent chat (do not start a new chat).
  - Cursor’s Agent input is a webview: keybindings cannot reliably type/submit into it (`type` goes to the editor instead). No Mac shortcut for auto-send `/commit` until Cursor exposes a prompt API that works from keybindings.

## Steps

1. In parallel: `git status`, `git diff` (staged + unstaged). Do **not** run `git log` or infer message style from history (see `.cursor/rules/git.mdc`).
2. Decide what belongs in **this** commit from the conversation / current task. Exclude unrelated dirty files (e.g. leftover docs). Never stage secrets (`.env`, `credentials.json`, `config/master.key`).
3. Stage the chosen paths with `git add`.
4. Draft the subject from `.cursor/rules/git.mdc` (this file only — including the scope glossary):
   - `type(scope): imperative description`
   - Types: `feat|fix|docs|style|refactor|test|chore|perf|build|ci`
   - Imperative, lowercase start, ≤ 72 chars, no trailing punctuation
5. Commit with HEREDOC (no `--no-verify`, no amend, no push, no git config):

```bash
git commit -m "$(cat <<'EOF'
type(scope): description

Optional body when the why is not obvious.

EOF
)"
```

6. If a hook fails, fix and create a **new** commit (do not amend).
7. Run `git status` and reply with the short hash + subject only.

## Out of scope

- Do not push unless the user explicitly asks in the same turn.
- Do not commit when the worktree has no relevant changes — say so briefly.
