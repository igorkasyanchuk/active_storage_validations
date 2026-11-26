#!/usr/bin/env ruby
# frozen_string_literal: true

# Compares each upstream's latest release (rubygems.org) and security
# advisories (GitHub) with the last review recorded in ../reviewed.yml.
#
#   ruby .cursor/skills/upstream-watch/scripts/check_upstreams.rb           # full report
#   ruby .cursor/skills/upstream-watch/scripts/check_upstreams.rb --quiet   # only what is new (commit step)
#
# Standard library only. Network errors are reported, never raised: the
# commit step must not fail because GitHub is unreachable.

require "date"
require "json"
require "net/http"
require "open3"
require "yaml"

QUIET = ARGV.include?("--quiet")
STATE_PATH = File.expand_path("../reviewed.yml", __dir__)
TIMEOUT = 5

def get_json(url)
  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
    response = http.get(uri.request_uri, "Accept" => "application/json", "User-Agent" => "asv-upstream-watch")
    response.is_a?(Net::HTTPSuccess) ? JSON.parse(response.body) : nil
  end
rescue StandardError
  nil
end

def versions_after(gem_name, reviewed)
  versions = get_json("https://rubygems.org/api/v1/versions/#{gem_name}.json")
  return nil unless versions

  reviewed_version = Gem::Version.new(reviewed)
  versions.reject { |version| version["prerelease"] }
          .map { |version| Gem::Version.new(version["number"]) }
          .select { |version| version > reviewed_version }
          .sort
end

# Repository advisories (gh, authenticated) list advisories before GitHub
# reviews them into the global database, which is the unauthenticated fallback.
def advisories_since(repo, gem_name, since)
  advisories = repository_advisories(repo) ||
    get_json("https://api.github.com/advisories?ecosystem=rubygems&affects=#{gem_name}&per_page=50")
  return nil unless advisories

  advisories.select do |advisory|
    published_on = Date.parse(advisory["published_at"].to_s)
    published_on >= since
  rescue Date::Error
    false
  end
end

def repository_advisories(repo)
  output, status = Open3.capture2("gh", "api", "repos/#{repo}/security-advisories?state=published&per_page=50", err: File::NULL)
  status.success? ? JSON.parse(output) : nil
rescue StandardError
  nil
end

state = YAML.safe_load_file(STATE_PATH)
news = []
errors = []

state.each do |name, upstream|
  reviewed_on = Date.parse(upstream.fetch("reviewed_on"))
  newer = versions_after(upstream.fetch("gem"), upstream.fetch("version"))
  advisories = advisories_since(upstream.fetch("repo"), upstream.fetch("gem"), reviewed_on)

  errors << "#{name}: could not reach rubygems.org" if newer.nil?
  errors << "#{name}: could not read GitHub advisories" if advisories.nil?

  lines = []
  lines << "new releases: #{newer.join(', ')}" if newer&.any?
  advisories&.each { |advisory| lines << "advisory #{advisory['ghsa_id']} (#{advisory['severity']}, #{advisory['published_at'][0, 10]}): #{advisory['summary']}" }

  if lines.any?
    news << [ name, upstream, lines ]
  elsif !QUIET
    puts "#{name}: up to date (reviewed #{upstream['version']} on #{upstream['reviewed_on']})"
  end
end

news.each do |name, upstream, lines|
  puts "#{name} (#{upstream['repo']}, reviewed #{upstream['version']} on #{upstream['reviewed_on']}):"
  lines.each { |line| puts "  - #{line}" }
end
puts "Run /upstream-watch to review: #{news.map(&:first).join(', ')}" if news.any? && QUIET
if QUIET
  warn "upstream-watch: #{errors.size} check(s) failed (offline?), run the script without --quiet for details" if errors.any?
else
  errors.each { |error| warn "upstream-watch: #{error}" }
end
