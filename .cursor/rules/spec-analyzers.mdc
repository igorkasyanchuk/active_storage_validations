---
description: Conventions for analyzer specs
globs: spec/analyzers/**/*.rb
alwaysApply: false
---

# Analyzer specs

- Follow shared conventions in `spec.mdc` (named `subject`, `describe`/`context`, `described_class`).
- Boot via `rails_helper`; `AnalyzerHelpers` is auto-included for `spec/analyzers`.
- Gate processor-specific examples with metadata `image_processor: :vips` / `:mini_magick` (filtered in `rails_helper` when `IMAGE_PROCESSOR` is set). Do not use `skip` for matrix gating — that reports pending in CI. Keep `skip` only for capability checks (missing gem / API).
- Stub external commands with RSpec mocks (`allow` / `allow_any_instance_of`), not Minitest `.stub` / `stub_any_instance`.
- Timeouts fail closed (empty metadata / validation errors) and may emit `timeout.active_storage_validations` — assert that per analyzer under `describe "timeouts"` (use `timed_out_command_result` from `AnalyzerHelpers`). Keep process-group / `run_command` mechanics in `commandable_spec.rb`.
- Metadata is cached on blobs as string keys `asv_*` via `ASVBlobMetadatable`; blobs are treated as immutable once keys exist.
- Prefer shared examples `"returns the right metadata for any attachable"` and `"works fine with 2 pages pdf"` when applicable.
