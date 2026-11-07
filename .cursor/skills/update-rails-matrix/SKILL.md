---
name: update-rails-matrix
description: >-
  Update the Ruby / Rails versions active_storage_validations is tested
  against. Assesses released and supported Rails series and Ruby versions,
  bumps each gemfiles/rails_*.gemfile lock to its latest Rails patch (raising
  the gemfile's version floor), adds a gemfile for a new Rails series, refreshes
  rails_next to Rails main, syncs the root Gemfile Rails pin, .ruby-version and
  the .github/workflows/main.yml CI matrix, then verifies with the suite. Use
  it whenever the user asks to bump, upgrade or refresh Rails or Ruby versions
  in the gemfiles, lockfiles or CI, mentions a new Rails or Ruby release
  (patch, minor, major, EOL), asks which versions we test or should test, or
  wants the test matrix updated, even if they name only one gemfile or one
  version.
---

# Update the Rails / Ruby test matrix

The gem claims a supported range in `active_storage_validations.gemspec` (Ruby `>= 3.3.0`, Rails `>= 7.0.1` at the time of writing). CI tests that claim with a matrix of `gemfiles/rails_X_Y.gemfile` × Ruby × image processor in `.github/workflows/main.yml`. The root `Gemfile` is the local default (exact Rails pin) and also feeds the linters and bench jobs. Keeping the matrix current means keeping three layers in line:

1. **Upstream**: which Rails series and Ruby versions exist, their latest patch, and whether they are still maintained.
2. **Claims**: gemspec floors, the README support sentence, `docs/upgrade_to_X.md`.
3. **Tests**: gemfiles + lockfiles, CI matrix and excludes, root `Gemfile`, `.ruby-version`.

Paths below are relative to the repo root. Run the scripts with plain `ruby` (no `bundle exec`): they use only the standard library and Bundler's lockfile parser.

## 1. Assess

```bash
ruby .cursor/skills/update-rails-matrix/scripts/assess_matrix.rb
```

It queries rubygems.org (Rails releases and the minimum Ruby of each one), endoflife.date (Rails/Ruby support windows) and `git ls-remote` (Rails main head). It compares those with the gemfiles, lockfiles, CI matrix, root Gemfile and `.ruby-version`, and prints a Ruby × gemfile grid plus suggested actions in four groups:

| Group | Typical items | What to do |
|---|---|---|
| Routine | lock behind the latest patch, floor behind the lock, rails_next behind main, root pin or `.ruby-version` behind, `BUNDLED WITH` drift, missing exclude, unquoted Ruby in YAML | Do it |
| Additive | new stable Rails series, new stable Ruby series, gemfile missing from CI | Do it and tell the user. It only adds coverage |
| Needs a project decision | EOL Rails series or Ruby still tested | Propose, don't act. See below |
| Worth a look | empirical excludes, coverage job not on the newest series | Mention, act only with evidence |

Why EOL removals are the user's call: an EOL series stays in CI because the gemspec still claims it. Dropping it alone would ship untested "support". Dropping it properly means raising the gemspec floor, which is a breaking change (CHANGES BREAKING entry, `docs/upgrade_to_X.md`, the README sentence "work with Rails 7.0.1 onwards and Ruby 3.3 onwards"). AGENTS.md also says not to change those floors without a project decision. Drop oldest-first: removing a middle series leaves a gap nobody tests.

If the user asked for something narrow ("bump 7.2"), do that, and list other findings in one line each instead of acting on them. If the plan includes additive or decision items, show a short before/after table before editing. Routine-only plans can go straight ahead.

## 2. Bump an existing gemfile to its latest patch

For each `gemfiles/rails_X_Y.gemfile` whose lock is behind:

1. **Raise the floor first** to the target patch:

   ```ruby
   %w[activejob activemodel activestorage activesupport].each { |rails_subcomponent| gem rails_subcomponent, '~> 7.2.0', '>= 7.2.4' }
   ```

   The floor is what makes the resolver take the new patch. Without it, Bundler may keep an older Rails so it can keep newer transitive gems. For example, Rails 7.2.4 caps `minitest < 6` and `connection_pool < 3`, and with only `~> 7.2.0` an update chose minitest 6.1 with Rails 7.2.3. The floor also stops future lock refreshes from sliding back.

2. **Update only the Rails gems**, lockfile only, conservatively. List the Rails gems present in that lock:

   ```bash
   BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle lock --update actionpack actionview activejob activemodel activerecord activestorage activesupport railties --conservative
   ```

   If resolution fails, the error names the transitive gems that have to move (e.g. `minitest`, `connection_pool`). Add exactly those to the list and rerun. Avoid a plain `bundle update`: it moves every gem (rspec, webmock, simplecov, prism…) and turns a Rails bump into a dependency sweep nobody can review.

3. `BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle install`

4. **Review the lock diff**:

   ```bash
   ruby .cursor/skills/update-rails-matrix/scripts/lock_changes.rb
   ```

   It lists the Rails moves, every other gem that moved, git revisions and `BUNDLED WITH`. It flags (and exits 1 on) any changed gem whose required Ruby the oldest CI Ruby for that lockfile can't satisfy. This matters because lockfiles are resolved on your local Ruby but shared by every Ruby in the matrix. Expect a few transitive moves forced by Rails (e.g. 8.0.5.2 / 8.1.4.1 needed `rails-html-sanitizer >= 1.7.2`, which pulled loofah and nokogiri). Explain each one in the report.

**rails_next** (Rails main via git): `bundle update rails --conservative` leaves the git revision where it is. Use:

```bash
BUNDLE_GEMFILE=gemfiles/rails_next.gemfile bundle update --source rails
```

The lock's `revision:` should now equal `git ls-remote https://github.com/rails/rails.git refs/heads/main`.

**Root Gemfile**: `gem "rails", "X.Y.Z"` is an exact pin on the newest stable patch of the newest stable series. Edit it, then run `bundle update rails --conservative`.

**Revisit pins while you are there.** Every extra pin in a gemfile has a comment saying why. Check that the reason still holds for the new patch, and report pins that became obsolete, with evidence. Example: `json < 3` on rails_8_1 existed because 8.1.3.1's `ActiveSupport::JSON.decode` called `JSON.parse(json, options)`; 8.1.4.1 calls `JSON.parse(json, **options)`. Read the installed gem's source (`bundle exec ruby -e 'print Gem.loaded_specs["activesupport"].full_gem_path'`) instead of guessing. Remove an obsolete pin only if the user agrees or asked for cleanup, and update the matching AGENTS.md pitfall.

## 3. Add a gemfile for a new Rails series

Only for a stable release (`X.Y.0` or later). Betas and RCs are what `rails_next` is for.

1. Seed from the newest existing pair so unrelated gems start from known-good versions: `/bin/cp -f gemfiles/rails_8_1.gemfile gemfiles/rails_8_2.gemfile` and the same for the `.lock`.
2. Set `'~> 8.2.0', '>= 8.2.Z'` and revisit every copied pin (see above). Keep only those still true for the new series.
3. Run step 2's `bundle lock --update … --conservative`, `bundle install`, `lock_changes.rb`.
4. Add the gemfile to the CI `gemfile:` list and to the BUNDLE_GEMFILE command lists in README.md and AGENTS.md.
5. Consider moving the root Gemfile pin and the coverage-upload condition (`matrix.gemfile == 'rails_8_1'`, mirrored in an AGENTS.md sentence) to the new series.
6. Expect fallout in the dummy app. Combustion ≥ 1.7 calls `config.load_defaults` for the running Rails version, so a new series brings new framework defaults to `test/dummy`. When specs fail only on the new series, first check whether a new default exposed a bug in a dummy model, and fix that rather than the spec. For example, `belongs_to` became required by default and exposed a wrong inferred foreign key in a nested-attributes model.

Version branches exist in lib, specs and dummy models (`Rails.gem_version >= Gem::Version.new("8.0.0")`, grep for `Rails.gem_version`). A new series rarely needs any. Dropping a series can leave dead branches. Clean those up only as part of a support drop.

## 4. Ruby versions and the CI matrix

In `.github/workflows/main.yml`:

- `matrix.ruby`: every non-EOL stable Ruby series at or above the gemspec floor. Quote them (`'4.0'`): YAML reads an unquoted `4.0` as a number, and setup-ruby then gets `4`, which resolves to the newest 4.x.
- `matrix.gemfile`: one entry per file in `gemfiles/`.
- `exclude`: combinations below a Rails series' minimum Ruby (the assess grid shows them), plus empirical incompatibilities such as Ruby 4.0 × rails_7_0_1. Keep an existing exclude unless you verified the combination. When adding a new Ruby series, run the oldest gemfile on it locally if that Ruby is installed, to decide whether it needs an exclude.
- `linters` job `ruby-version`: same exact version as `.ruby-version`. Its comment calls it the recommended Ruby for the root Gemfile.
- The coverage upload `if:` and the AGENTS.md sentence about it stay in sync.
- `.github/workflows/bench.yml` (`ruby-version: "3.4"`) also uses the root Gemfile. Change it only if asked, since `benchmark/BASELINE.md` was recorded on it.
- Check the YAML still parses: `ruby -ryaml -e 'YAML.load_file(".github/workflows/main.yml")'`.

`.ruby-version`: the latest patch of the newest stable Ruby series.

**Bundler**: keep `BUNDLED WITH` identical across every lockfile (2.7.1 at the time of writing). The assess report flags drift. A stale Bundler caused real breakage: on Ruby 4.0, Bundler 2.6.3 prints `Gem::Platform` redefinition warnings into the stderr of every Ruby subprocess started under `bundle exec`, which broke an exact-stderr spec. Change the Bundler version deliberately and everywhere: `bundle update --bundler=<version>` per lockfile.

## 5. Docs

- `CHANGES.md` → Unreleased → MISC: one line naming the new versions, e.g. "Bump the CI gemfiles to the latest Rails patches (7.2.4, 8.0.5.2, 8.1.4.1, main)".
- `AGENTS.md`: the Supported Versions section ("CI also covers 3.4 and 4.0"), the BUNDLE_GEMFILE command lists, "Local default Gemfile … (currently 8.1.x)", the coverage job sentence, and pitfalls that name specific patch versions.
- `README.md`: the "Running tests" command lists when gemfiles are added or removed. The support sentence only changes when the gemspec floor changes.
- `docs/upgrade_to_X.md`: only for support drops.

## 6. Verify

- `bundle check` with each `BUNDLE_GEMFILE`.
- The full suite for each changed gemfile, **one at a time** (runs share the Combustion SQLite file):

  ```bash
  BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile NO_COVERAGE=1 bundle exec rake spec
  ```

  Example counts differ by series (Rails < 8.0 skips the `except_on` examples, about 2783 vs 2926). That is expected.
- On a failure, check whether it predates your change before blaming the bump. `git stash`, `bundle install`, rerun the failing examples, then `git stash pop` and `bundle install` again. Earlier failures came from a Combustion upgrade and a stale Bundler, not from Rails.
- `bundle exec rubocop --parallel` if any Ruby file changed.
- Say what the local runs did not cover: other Ruby versions, the other image processor (`IMAGE_PROCESSOR=vips|mini_magick`), live Magika. CI covers those after a push.

## 7. Report and commit

Report:

- a before → after table per gemfile, with suite results
- CI matrix changes
- pins reviewed (kept or obsolete, with evidence)
- notable transitive moves
- decisions left to the user
- what was not verified

Commit only when asked, following `.cursor/rules/git.mdc`. Examples:

- `ci(gemfiles): bump Rails locks to latest patches and floor constraints`
- `chore(deps): bump local Rails pin to 8.1.4.1`
- `ci: add Ruby 4.1 to the test matrix`
- `chore(ruby): bump dev Ruby to 4.0.9 and root Bundler to 2.7.1`

Don't push unless asked.

## Shell gotchas

- `cp`, `mv` and `rm` may be aliased to interactive versions (`cp -i`), which silently skip overwrites in a non-interactive shell. Use `/bin/cp -f` and `/bin/rm -f`.
- In zsh, an unquoted `$GEMS` is not word-split, so `bundle update $GEMS` passes one argument. Write the gem names out, or use `${=GEMS}` in zsh.
- Temporary gemfiles must live in `gemfiles/`, because `gemspec :path => '../'` is relative. Name them `tmp_*`, delete them, and check that `git status` shows none left.
- `bundle outdated`'s "Latest" column is the newest release of any series (8.1.x for a 7.2 gemfile). Use the assess report for the latest patch of each series.
