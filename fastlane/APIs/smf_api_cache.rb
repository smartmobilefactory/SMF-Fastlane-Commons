require 'json'
require 'fileutils'
require 'tmpdir'

# Per-build cache for GitHub and Jira lookups of the changelog (RWCIT-2102).
#
# Group builds generate the changelog once per variant, every time in a new fastlane
# process, and the iOS parallel mode generates it a second time in the main workspace.
# Each run resolved the same merge commits (GitHub API) and tickets (Jira API, often
# against two Atlassian hosts) again: 25-36 s per variant for 9 variants.
#
# Results are stored as JSON under the system temp directory, keyed by BUILD_TAG, so
# every fastlane run and parallel slot of one Jenkins build shares them and nothing
# leaks into the next build. Outside Jenkins (no BUILD_TAG) nothing is cached.

SMF_API_CACHE_MAX_AGE_SECONDS = 2 * 24 * 60 * 60

def smf_api_cache_dir
  build_tag = ENV['BUILD_TAG'].to_s
  return nil if build_tag.empty?

  root = File.join(Dir.tmpdir, 'smf-api-cache')
  dir = File.join(root, build_tag.gsub(/[^A-Za-z0-9._-]/, '_'))
  unless Dir.exist?(dir)
    _smf_prune_api_cache(root)
    FileUtils.mkdir_p(dir)
  end
  dir
rescue StandardError
  nil
end

# Returns the cached value for `kind`/`key`, or yields, caches a non-nil result and
# returns it. A broken cache entry is ignored and fetched again.
def smf_api_cached(kind, key)
  dir = smf_api_cache_dir
  return yield if dir.nil?

  file = File.join(dir, "#{kind}-#{key.to_s.gsub(/[^A-Za-z0-9._-]/, '_')}.json")
  if File.exist?(file)
    begin
      return JSON.parse(File.read(file), symbolize_names: true)
    rescue StandardError
      # fall through and fetch again
    end
  end

  value = yield
  unless value.nil?
    begin
      tmp = "#{file}.#{Process.pid}"
      File.write(tmp, JSON.generate(value))
      File.rename(tmp, file)
    rescue StandardError
      # caching is best effort
    end
  end
  value
end

def _smf_prune_api_cache(root)
  return unless Dir.exist?(root)

  Dir.children(root).each do |entry|
    path = File.join(root, entry)
    FileUtils.rm_rf(path) if File.mtime(path) < Time.now - SMF_API_CACHE_MAX_AGE_SECONDS
  end
rescue StandardError
  # pruning is best effort
end
