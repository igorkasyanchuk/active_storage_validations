# Claude Code — Active Storage Validations

This repo's conventions live in `AGENTS.md` and `.cursor/rules/`, shared with Cursor. This file does one thing: **make those rules reachable from Claude Code**, which has no `alwaysApply` / `globs` auto-attach.

Nothing here restates architecture, commands or pitfalls. `AGENTS.md` is canonical for the gem, and each `.cursor/rules/*.mdc` is canonical for its area — **if this file ever disagrees with them, they win.**

## Read first, every coding turn

`AGENTS.md` is the project guide (architecture, supported versions, test commands, conventions, pitfalls). If it is not already in your context, read it before the first edit:

```bash
cat AGENTS.md
```

`.cursor/rules/git.mdc` is `alwaysApply: true` in Cursor. Read it before drafting any commit message or PR title (see `/commit` below).

## Read before touching a path

Claude Code does not auto-attach by glob. Read the matching rule **before** editing that path — this table is the `globs:` frontmatter, inverted:

| Path you're about to edit | `cat .cursor/rules/…` |
|---|---|
| `spec/**/*.rb` | `spec.mdc` |
| `spec/validators/**/*.rb` | `spec.mdc` + `spec-validators.mdc` |
| `spec/matchers/**/*.rb` | `spec.mdc` + `spec-matchers.mdc` |
| `spec/analyzers/**/*.rb` | `spec.mdc` + `spec-analyzers.mdc` |
| `spec/**/integration/**/*.rb` | `spec.mdc` + `spec-integration.mdc` |
| drafting a commit message or PR title | `git.mdc` |

Several rows can match at once (`spec/validators/integration/…` reads `spec.mdc`, `spec-validators.mdc` and `spec-integration.mdc`) — read all of them.

## Cursor mechanics → Claude Code equivalents

| `.cursor/…` says | Here it means |
|---|---|
| `@`-mention a rule | `cat` that file before writing code |
| "Slash `/commit` in Agent chat" / webview and keybinding notes | `/commit` works natively here (`.claude/skills/commit/`) |
| `.cursor/skills/<name>/SKILL.md` | `.claude/skills/<name>/SKILL.md` wraps it and delegates to the Cursor file |

## Slash commands

`/commit` → `.claude/skills/commit/` delegates to `.cursor/skills/commit/SKILL.md` + `.cursor/rules/git.mdc`. Same behaviour as Cursor.

## Keeping both tools in sync

- Change a convention in `.cursor/rules/` or `AGENTS.md`, never only here.
- Adding a rule with `globs:` → add its row to the table above.
- Adding a Cursor skill → add a thin wrapper under `.claude/skills/` that `cat`s it, like `commit`.
