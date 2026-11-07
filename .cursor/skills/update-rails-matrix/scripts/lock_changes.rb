#!/usr/bin/env ruby
# frozen_string_literal: true

# Summarize gem version changes in lockfiles against a git ref, and flag any
# changed gem whose required Ruby the oldest CI Ruby for that lockfile cannot
# satisfy (lockfiles are resolved on your local Ruby but shared by every Ruby
# in the CI matrix).
#
# Usage (from the repo root, plain `ruby`):
#   ruby .cursor/skills/update-rails-matrix/scripts/lock_changes.rb [--base REF] [--offline] [LOCKFILE ...]
#
# Defaults: --base HEAD, and every Gemfile.lock / gemfiles/*.lock that differs
# from it (including new, untracked lockfiles). --offline skips the
# rubygems.org lookup of required Ruby versions.

require "bundler"
require "json"
require "net/http"
require "open3"
require "uri"
require "yaml"

RAILS_GEMS = %w[
  actioncable actionmailbox actionmailer actionpack actiontext actionview activejob
  activemodel activerecord activestorage activesupport rails railties
].freeze

args = ARGV.dup
base = "HEAD"
if (i = args.index("--base"))
  base = args[i + 1] or abort("--base needs a git ref")
  args.slice!(i, 2)
end
offline = !args.delete("--offline").nil?

def git(*cmd)
  out, status = Open3.capture2("git", *cmd, err: File::NULL)
  status.success? ? out : nil
end

def ver(str) = Gem::Version.new(str.to_s)

locks = if args.empty?
  changed = git("diff", "--name-only", base, "--", "Gemfile.lock", "gemfiles").to_s.split("\n")
  untracked = git("ls-files", "--others", "--exclude-standard", "--", "gemfiles").to_s.split("\n")
  (changed + untracked).select { |p| p.end_with?(".lock") }.uniq.sort
else
  args
end
if locks.empty?
  puts "No lockfile differs from #{base}."
  exit
end

# Oldest Ruby that CI runs each lockfile on.
workflows = Dir[".github/workflows/*.yml"].to_h { |path| [ path, YAML.load_file(path) ] }
matrix = workflows.dig(".github/workflows/main.yml", "jobs", "tests", "strategy", "matrix") || {}
literal_rubies = workflows.values.flat_map do |wf|
  wf.fetch("jobs", {}).values.flat_map { |job| Array(job["steps"]) }
    .select { |s| s["uses"].to_s.start_with?("ruby/setup-ruby") }
    .map { |s| s.dig("with", "ruby-version").to_s }
    .reject { |r| r.empty? || r.include?("${{") }
end

min_ruby_for = lambda do |lock|
  rubies =
    if lock.start_with?("gemfiles/")
      gemfile = File.basename(lock, ".gemfile.lock")
      excluded = Array(matrix["exclude"]).select { |e| e["gemfile"].to_s == gemfile }.map { |e| e["ruby"].to_s }
      Array(matrix["ruby"]).map(&:to_s) - excluded
    else
      literal_rubies # jobs using the root Gemfile (linters, bench)
    end
  rubies.min_by { |r| ver(r) }
end

def specs_of(content)
  return [ {}, {} ] if content.nil? || content.empty?

  parser = Bundler::LockfileParser.new(content)
  gems = {}
  git_revisions = {}
  parser.specs.each do |spec|
    if spec.source.is_a?(Bundler::Source::Git)
      git_revisions[spec.source.uri] = spec.source.revision
    else
      (gems[spec.name] ||= []) << spec.version.to_s
    end
  end
  [ gems.transform_values(&:uniq), git_revisions ]
end

def bundled_with(content) = content.to_s[/BUNDLED WITH\n\s+(\S+)/, 1]

@ruby_req_cache = {}
def required_ruby(name, version)
  @ruby_req_cache[[ name, version ]] ||= begin
    uri = URI("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 20) do |http|
      http.get(uri.request_uri, "User-Agent" => "asv-update-rails-matrix")
    end
    response.is_a?(Net::HTTPSuccess) ? JSON.parse(response.body.dup.force_encoding(Encoding::UTF_8))["ruby_version"] : nil
  rescue StandardError
    nil
  end
end

def satisfied?(requirement, ruby)
  return true if requirement.nil? || requirement.empty? || ruby.nil?

  Gem::Requirement.new(requirement.split(",").map(&:strip)).satisfied_by?(ver(ruby))
end

problems = 0
locks.each do |lock|
  old_content = git("show", "#{base}:#{lock}")
  new_content = File.exist?(lock) ? File.read(lock) : nil
  old_gems, old_git = specs_of(old_content)
  new_gems, new_git = specs_of(new_content)
  min_ruby = min_ruby_for.call(lock)

  puts "== #{lock}#{old_content ? '' : ' (new)'}#{new_content ? '' : ' (deleted)'} | oldest CI Ruby: #{min_ruby || 'unknown'}"

  changed = (old_gems.keys | new_gems.keys).sort.filter_map do |name|
    before = old_gems[name]
    after = new_gems[name]
    next if before == after

    [ name, before&.join("/"), after&.join("/") ]
  end
  rails, others = changed.partition { |name, _, _| RAILS_GEMS.include?(name) }

  unless rails.empty?
    pairs = rails.map { |_, b, a| "#{b || 'none'} -> #{a || 'removed'}" }.uniq
    puts "Rails gems (#{rails.size}): #{pairs.join(', ')}"
  end
  (old_git.keys | new_git.keys).each do |uri|
    next if old_git[uri] == new_git[uri]

    puts "Git #{uri}: #{old_git[uri]&.slice(0, 7) || 'none'} -> #{new_git[uri]&.slice(0, 7) || 'removed'}"
  end

  if changed.empty? && old_git == new_git
    puts "No gem versions changed (only DEPENDENCIES or other metadata lines)"
  elsif others.empty?
    puts "Other gems: none changed"
  else
    width = others.map { |name, _, _| name.size }.max
    puts "Other gems:"
    others.each do |name, before, after|
      req = after && !offline ? required_ruby(name, after.split("/").first) : nil
      flag = satisfied?(req, min_ruby) ? "" : "  !! needs Ruby #{req}, CI runs this lock on #{min_ruby}"
      problems += 1 unless flag.empty?
      label = if before.nil? then "added #{after}"
      elsif after.nil? then "removed (was #{before})"
      else "#{before} -> #{after}"
      end
      puts "  #{name.ljust(width)}  #{label}#{req ? "  (ruby #{req})" : ''}#{flag}"
    end
  end

  old_bw = bundled_with(old_content)
  new_bw = bundled_with(new_content)
  puts(old_bw == new_bw ? "BUNDLED WITH #{new_bw} (unchanged)" : "BUNDLED WITH #{old_bw || 'none'} -> #{new_bw || 'none'}  !! check this was intended")
  puts
end

exit(problems.zero? ? 0 : 1)
