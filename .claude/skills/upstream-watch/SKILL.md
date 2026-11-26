---
name: upstream-watch
description: >-
  Check the gems active_storage_validations copies practices from
  (image_processing, Active Storage, Marcel, ruby-vips, mini_magick) for new
  releases and security advisories since the last review, read what changed,
  and decide what this gem should copy. Use when the user runs
  /upstream-watch, when the commit step reports new upstream releases, or when
  the user mentions a release or advisory of one of those gems.
---

# Upstream watch

This skill is a thin wrapper. The procedure lives in the Cursor skill so both
tools stay in sync:

```bash
cat .cursor/skills/upstream-watch/SKILL.md
```

Follow it exactly. The state file is `.cursor/skills/upstream-watch/reviewed.yml`
and the check script is `.cursor/skills/upstream-watch/scripts/check_upstreams.rb`.
