#!/usr/bin/env ruby
# frozen_string_literal: true

# Assess the Ruby / Rails test matrix of active_storage_validations.
#
# Usage (from the repo root, plain `ruby`, network required):
#   ruby .cursor/skills/update-rails-matrix/scripts/assess_matrix.rb
#
# Compares what upstream has released and still supports (rubygems.org,
# endoflife.date, Rails main on GitHub) with what this repo claims (gemspec)
# and tests (gemfiles/*.gemfile + locks, .github/workflows/main.yml, root
# Gemfile, .ruby-version), then prints suggested actions grouped as
# routine / additive / needs a project decision.

require "date"
require "json"
require "net/http"
require "open3"
require "rubygems"
require "uri"
require "yaml"

TODAY = Date.today
RAILS_REPO = "https://github.com/rails/rails.git"

def fetch_json(url)
  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
    http.get(uri.request_uri, "User-Agent" => "asv-update-rails-matrix")
  end
  return JSON.parse(response.body.dup.force_encoding(Encoding::UTF_8)) if response.is_a?(Net::HTTPSuccess)

  warn "! #{url} -> HTTP #{response.code}"
  nil
rescue StandardError => e
  warn "! #{url} -> #{e.class}: #{e.message}"
  nil
end

def ver(str) = Gem::Version.new(str.to_s)
def series_of(version) = version.to_s.split(".").first(2).join(".")

def to_date(value)
  value.is_a?(String) ? Date.parse(value) : value
rescue Date::Error
  nil
end

# endoflife.date: `support` = end of bug fixes, `eol` = end of security fixes.
def status_for(cycle_info)
  return "no EOL data yet" unless cycle_info

  eol = to_date(cycle_info["eol"])
  support = to_date(cycle_info["support"])
  return "EOL" if eol == true || (eol.is_a?(Date) && eol <= TODAY)
  return "security only" if support.is_a?(Date) && support <= TODAY

  "maintained"
end

def dates_for(cycle_info)
  return "" unless cycle_info

  [ cycle_info["support"], cycle_info["eol"] ].map { |d| d.is_a?(String) ? d : "-" }.join(" / ")
end

def table(headers, rows)
  lines = [ "| #{headers.join(' | ')} |", "|#{headers.map { '---' }.join('|')}|" ]
  rows.each { |row| lines << "| #{row.map { |c| c.to_s.empty? ? '-' : c }.join(' | ')} |" }
  lines.join("\n")
end

abort "Run from the repo root (active_storage_validations.gemspec not found)" unless File.exist?("active_storage_validations.gemspec")

# --- What the gem claims ------------------------------------------------------
gemspec = Gem::Specification.load("active_storage_validations.gemspec")
ruby_floor_req = gemspec.required_ruby_version
rails_floor_req = gemspec.dependencies.find { |d| d.name == "activesupport" }&.requirement
lower_bound = ->(req) { req&.requirements&.find { |op, _| op.start_with?(">") }&.last }
ruby_floor_series = series_of(lower_bound.call(ruby_floor_req) || "0.0")
rails_floor_series = series_of(lower_bound.call(rails_floor_req) || "0.0")

# --- Upstream -----------------------------------------------------------------
rails_versions = fetch_json("https://rubygems.org/api/v1/versions/activesupport.json") || []
stable = rails_versions.reject { |r| r["prerelease"] }
latest_rails = stable.group_by { |r| series_of(r["number"]) }.transform_values { |rs| rs.max_by { |r| ver(r["number"]) } }
newest_prerelease = rails_versions.select { |r| r["prerelease"] }.max_by { |r| ver(r["number"]) }
rails_eol = (fetch_json("https://endoflife.date/api/rails.json") || []).to_h { |c| [ c["cycle"].to_s, c ] }
ruby_cycles = (fetch_json("https://endoflife.date/api/ruby.json") || []).select { |c| ver(c["cycle"]) >= ver(ruby_floor_series) }
                                                                       .sort_by { |c| ver(c["cycle"]) }.reverse
main_head, = Open3.capture2("git", "ls-remote", RAILS_REPO, "refs/heads/main")
main_head = main_head.split.first

# --- What the repo tests --------------------------------------------------------
GemfileInfo = Struct.new(:name, :series, :floor, :locked, :revision, :bundled_with, keyword_init: true)
gemfiles = Dir["gemfiles/*.gemfile"].sort.map do |path|
  src = File.read(path)
  lock = File.exist?("#{path}.lock") ? File.read("#{path}.lock") : ""
  info = GemfileInfo.new(name: File.basename(path, ".gemfile"),
                     locked: lock[/^    activesupport \(([^)]+)\)/, 1],
                     revision: lock[%r{remote: https://github\.com/rails/rails(?:\.git)?\n\s+revision: (\h+)}, 1],
                     bundled_with: lock[/BUNDLED WITH\n\s+(\S+)/, 1])
  if src.match?(%r{github:\s*['"]rails/rails['"]})
    info.series = "main"
  else
    reqs = src[/rails_subcomponent,\s*(.+?)\s*\}/, 1].to_s.scan(/['"]([^'"]+)['"]/).flatten
    info.series = reqs.find { |r| r.start_with?("~>") }&.then { |r| series_of(r.delete_prefix("~>").strip) }
    info.floor = reqs.find { |r| r.start_with?(">=") }&.delete_prefix(">=")&.strip
  end
  info
end
by_series = gemfiles.to_h { |g| [ g.series, g ] }

workflow = YAML.load_file(".github/workflows/main.yml")
matrix = workflow.dig("jobs", "tests", "strategy", "matrix") || {}
raw_rubies = Array(matrix["ruby"])
ci_rubies = raw_rubies.map(&:to_s)
ci_gemfiles = Array(matrix["gemfile"]).map(&:to_s)
excludes = Array(matrix["exclude"]).map { |e| [ e["ruby"].to_s, e["gemfile"].to_s ] }
setup_ruby = ->(steps) { Array(steps).find { |s| s["uses"].to_s.start_with?("ruby/setup-ruby") } }
linters_ruby = setup_ruby.call(workflow.dig("jobs", "linters", "steps"))&.dig("with", "ruby-version")&.to_s
coverage_if = Array(workflow.dig("jobs", "tests", "steps")).find { |s| s["name"].to_s.match?(/coverage/i) }&.fetch("if", nil)

root_pin = File.read("Gemfile")[/^gem ["']rails["'],\s*["']([^"']+)["']/, 1]
root_lock = File.exist?("Gemfile.lock") ? File.read("Gemfile.lock") : ""
root_locked = root_lock[/^    rails \(([^)]+)\)/, 1]
root_bundled_with = root_lock[/BUNDLED WITH\n\s+(\S+)/, 1]
ruby_version_file = File.exist?(".ruby-version") ? File.read(".ruby-version").strip : nil

rails_series = latest_rails.keys.select { |s| ver(s) >= ver(rails_floor_series) }.sort_by { |s| ver(s) }.reverse
newest_stable_series = rails_series.first
min_ruby_for = ->(series) { latest_rails[series]&.dig("ruby_version") }

routine = []
additive = []
decisions = []
checks = []
eol_rails = []

# --- Report -----------------------------------------------------------------------
puts "# Rails / Ruby test matrix assessment (#{TODAY})"
puts
puts "Gem claims (gemspec): Ruby #{ruby_floor_req}, Rails (activesupport) #{rails_floor_req}"
puts

puts "## Rails series (>= #{rails_floor_series})"
puts
rails_rows = rails_series.map do |s|
  g = by_series[s]
  latest = latest_rails[s]["number"]
  if g
    if g.locked && ver(g.locked) < ver(latest)
      routine << "Bump gemfiles/#{g.name} lock #{g.locked} -> #{latest}; raise its floor to '>= #{latest}' first"
    elsif g.floor.nil? || (g.locked && ver(g.floor) < ver(g.locked))
      routine << "Raise the floor in gemfiles/#{g.name}.gemfile to '>= #{g.locked}' (currently #{g.floor || 'none'})"
    end
    eol_rails << "#{s} (#{rails_eol[s]['eol']})" if status_for(rails_eol[s]) == "EOL"
  else
    additive << "Add gemfiles/rails_#{s.tr('.', '_')}.gemfile for Rails #{s} (latest #{latest}) and add it to the CI matrix"
  end
  [ s, latest, min_ruby_for.call(s), "#{status_for(rails_eol[s])} (#{dates_for(rails_eol[s])})",
    g&.name, g&.locked, g&.floor, g && ci_gemfiles.include?(g.name) ? "yes" : "no" ]
end
if (main = by_series["main"])
  head = main_head ? main_head[0, 7] : "unknown"
  locked = main.revision ? main.revision[0, 7] : "?"
  routine << "Refresh gemfiles/#{main.name} to Rails main #{head} (bundle update --source rails)" if main_head && main.revision && main_head != main.revision
  rails_rows << [ "main", main.locked, "", "head #{head}", main.name, "rev #{locked}", "", ci_gemfiles.include?(main.name) ? "yes" : "no" ]
end
unless eol_rails.empty?
  decisions << "Rails #{eol_rails.reverse.join(', ')} are EOL upstream but still tested, because the gemspec claims #{rails_floor_req}. " \
               "Keep them, or drop the oldest series and raise the gemspec floor to match (breaking: CHANGES BREAKING, " \
               "docs/upgrade_to_X.md, README support sentence). Dropping a middle series alone would leave an untested gap"
end
puts table([ "Series", "Latest", "Min Ruby", "Status (bugfix end / security end)", "Gemfile", "Locked", "Floor", "In CI" ], rails_rows)
puts
if newest_prerelease && ver(series_of(newest_prerelease["number"])) > ver(newest_stable_series)
  puts "Newest prerelease: #{newest_prerelease['number']} (#{newest_prerelease['created_at'][0, 10]}) - covered by rails_next; " \
       "add a gemfile once a stable #{series_of(newest_prerelease['number'])}.0 ships"
else
  puts "Newest prerelease: #{newest_prerelease ? newest_prerelease['number'] : 'none'} (not ahead of #{newest_stable_series}; nothing to add)"
end
puts

puts "## Ruby series (>= #{ruby_floor_series})"
puts
ruby_rows = ruby_cycles.map do |c|
  status = status_for(c)
  in_ci = ci_rubies.include?(c["cycle"].to_s)
  additive << "Add Ruby #{c['cycle']} to the CI matrix (latest #{c['latest']})" if !in_ci && status != "EOL"
  if in_ci && status == "EOL"
    decisions << "CI still runs Ruby #{c['cycle']}, EOL since #{c['eol']}, because the gemspec claims Ruby #{ruby_floor_req}. " \
                 "Keep it, or drop it together with a gemspec required_ruby_version bump (breaking change)"
  end
  [ c["cycle"], c["latest"], c["releaseDate"], c["eol"], status, in_ci ? "yes" : "no" ]
end
puts table([ "Series", "Latest", "Released", "EOL", "Status", "In CI" ], ruby_rows)
puts
(ci_rubies - ruby_cycles.map { |c| c["cycle"].to_s }).each do |r|
  routine << "CI runs Ruby #{r}, which is below the gemspec floor (#{ruby_floor_req}) or unknown upstream: remove it"
end
raw_rubies.each do |r|
  routine << "Quote Ruby #{r.inspect} in the CI matrix ('#{r}'): unquoted YAML numbers lose trailing zeros (4.0 -> 4)" unless r.is_a?(String)
end

newest_ruby = ruby_cycles.find { |c| status_for(c) != "EOL" }
if newest_ruby
  latest_ruby = newest_ruby["latest"].to_s
  routine << ".ruby-version is #{ruby_version_file.inspect}; latest Ruby is #{latest_ruby}" if ruby_version_file != latest_ruby
  routine << "CI linters ruby-version is #{linters_ruby.inspect}; keep it equal to .ruby-version (#{ruby_version_file})" if linters_ruby != ruby_version_file
end

puts "## CI matrix (.github/workflows/main.yml)"
puts
puts "Ruby: #{ci_rubies.join(', ')} | Gemfiles: #{ci_gemfiles.join(', ')}"
puts "Excludes: #{excludes.empty? ? 'none' : excludes.map { |r, g| "#{r} x #{g}" }.join(', ')}"
puts "Linters job Ruby: #{linters_ruby} | Coverage upload if: #{coverage_if || 'n/a'}"
puts
grid = gemfiles.map do |g|
  min_req = g.series == "main" ? nil : min_ruby_for.call(g.series)
  cells = ci_rubies.map do |r|
    below = min_req && !Gem::Requirement.new(min_req.split(",").map(&:strip)).satisfied_by?(ver("#{r}.0"))
    excluded = excludes.include?([ r, g.name ])
    if below && !excluded
      routine << "Exclude Ruby #{r} x #{g.name} in CI: Rails #{g.series} needs Ruby #{min_req}"
      "below min, NOT excluded"
    elsif excluded
      checks << "Ruby #{r} x #{g.name} is excluded although Rails #{g.series} allows Ruby #{min_req}: an empirical exclusion, keep it unless you verified the combination" unless below
      "excluded"
    else
      "run"
    end
  end
  [ g.name, *cells ]
end
puts table([ "Gemfile", *ci_rubies.map { |r| "Ruby #{r}" } ], grid)
puts
(gemfiles.map(&:name) - ci_gemfiles).each { |n| additive << "gemfiles/#{n}.gemfile exists but is not in the CI matrix" }
(ci_gemfiles - gemfiles.map(&:name)).each { |n| routine << "CI matrix lists #{n} but gemfiles/#{n}.gemfile does not exist" }
if coverage_if && newest_stable_series && by_series[newest_stable_series] && !coverage_if.include?(by_series[newest_stable_series].name)
  checks << "Coverage upload runs on a gemfile other than the newest stable series (#{by_series[newest_stable_series].name}); consider moving it (and the AGENTS.md sentence)"
end

puts "## Root Gemfile"
puts
latest_overall = newest_stable_series && latest_rails[newest_stable_series]["number"]
puts "Rails pin #{root_pin} (locked #{root_locked}); newest stable Rails #{latest_overall}; .ruby-version #{ruby_version_file}"
if root_pin && latest_overall && ver(root_pin) < ver(latest_overall)
  bucket = series_of(root_pin) == newest_stable_series ? routine : additive
  bucket << "Bump the root Gemfile Rails pin #{root_pin} -> #{latest_overall}"
end
bundled = { "Gemfile.lock" => root_bundled_with }.merge(gemfiles.to_h { |g| [ "gemfiles/#{g.name}.gemfile.lock", g.bundled_with ] })
puts "BUNDLED WITH: #{bundled.group_by { |_, v| v }.map { |v, ls| "#{v} (#{ls.size} lockfiles)" }.join(', ')}"
if bundled.values.uniq.size > 1
  majority = bundled.values.tally.max_by { |_, n| n }.first
  bundled.reject { |_, v| v == majority }.each_key { |l| routine << "#{l} is BUNDLED WITH #{bundled[l]}; the other lockfiles use #{majority}" }
end
puts

puts "## Suggested actions"
puts
{ "Routine (do it)" => routine, "Additive (do it, tell the user)" => additive,
  "Needs a project decision (propose, do not act alone)" => decisions, "Worth a look" => checks }.each do |title, items|
  puts "### #{title}"
  puts(items.empty? ? "- none" : items.uniq.map { |i| "- #{i}" })
  puts
end
