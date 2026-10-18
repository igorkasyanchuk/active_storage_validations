---
name: commit
description: >-
  Create a git commit for the current worktree changes using Conventional
  Commits and this repo's git rules. Use when the user runs /commit or asks
  to commit.
disable-model-invocation: true
---

# Commit

This skill is a thin wrapper. The procedure is **not** duplicated here — it lives in the
Cursor skill so both tools stay in sync.

## Gate (check before anything else)

Commit only when the user's own message asks for a commit (`/commit`, or a direct request
such as "commit this").

This skill being attached is not approval. If the message also asks to implement, fix, add,
or change something — do the work and stop. Do not commit.

## Procedure

When the gate passes, read both files and follow them exactly:

```bash
cat .cursor/skills/commit/SKILL.md .cursor/rules/git.mdc
```

`.cursor/skills/commit/SKILL.md` is the authority on steps; `git.mdc` is the authority on
message format and the scope glossary.

Skip the Cursor-only part: the webview / keybinding notes under "How the user invokes this" —
`/commit` works natively here.

Two points worth repeating because they override general habits:

- **Do not run `git log`** or infer message style from history. Use `git.mdc` only.
- **Do not push, amend, or `--no-verify`** unless the user asks in the same message. If a
  hook fails, fix it and create a new commit.

Reply with the short hash + subject only.
