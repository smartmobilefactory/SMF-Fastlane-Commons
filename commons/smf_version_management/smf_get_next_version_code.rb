# Get next version code from Git tags
# This eliminates the need to commit Config.json/Info.plist for every build
#
# Strategy:
# 1. Query all build tags from Git
# 2. Extract highest version code
# 3. Increment by 1
# 4. Fallback to Config.json if no tags exist
#
# Usage:
#   version_code = smf_get_next_version_code_from_tags('android')
#   version_code = smf_get_next_version_code_from_tags('ios')
#

def smf_get_next_version_code_from_tags(platform = nil)
  UI.message("🔍 Querying Git tags for version code...")

  begin
    # Fetch build tags (optimized: only once per build, only build/* tags)
    _smf_fetch_build_tags_once

    # Query all build tags and extract version codes
    # New format: build/ios/de_alpha/3548 or build/android/de_alpha/3548
    # Legacy format: build/de_alpha/3548
    # Extract: 3548 (last number segment, works for both formats)
    all_version_codes = sh(
      "{ git tag -l 'build/*/*/*' 2>/dev/null; git tag -l 'build/*/*' 2>/dev/null; } | grep -oE '[0-9]+$' | sort -n | uniq",
      log: false
    ).strip

    if all_version_codes.empty?
      # No tags found - fallback to Config.json
      base_version = @smf_fastlane_config[:app_version_code] || 1
      UI.important("⚠️  No Git tags found, using Config.json: #{base_version}")
      UI.important("💡 This is expected for first build or new repository")
      return base_version
    end

    # Get highest version code from all tags
    highest_version = all_version_codes.split("\n").last.to_i
    next_version = highest_version + 1

    UI.message("📊 Highest versionCode from Git tags: #{highest_version}")
    UI.message("🚀 Next versionCode: #{next_version}")

    return next_version

  rescue => e
    # Error reading tags - fallback to Config.json
    UI.error("❌ Error reading Git tags: #{e.message}")
    base_version = @smf_fastlane_config[:app_version_code] || 1
    UI.important("⚠️  Falling back to Config.json: #{base_version}")
    return base_version
  end
end

# Check if running in CI environment
def smf_is_ci?
  !ENV['BUILD_NUMBER'].nil? ||
  !ENV['CI'].nil? ||
  !ENV['JENKINS_HOME'].nil? ||
  !ENV['JENKINS_URL'].nil?
end

# Get current version code from built artifact
# This is used after build to verify the version code
def smf_get_current_version_code_from_apk(apk_path)
  UI.message("📦 Extracting versionCode from APK...")

  begin
    version_code_output = sh(
      "aapt dump badging '#{apk_path}' | grep versionCode | awk '{print $3}' | sed 's/[^0-9]//g'",
      log: false
    ).strip

    version_code = version_code_output.to_i

    if version_code > 0
      UI.message("✅ Extracted versionCode from APK: #{version_code}")
      return version_code
    else
      UI.error("❌ Could not extract valid versionCode from APK")
      return nil
    end

  rescue => e
    UI.error("❌ Error extracting versionCode from APK: #{e.message}")
    return nil
  end
end

# Get CURRENT highest version code from Git tags (for group builds - reuse same version)
# This is used when IS_GROUP_BUILD=true to ensure all builds in a group use the same version code
def smf_get_current_version_code_from_tags(platform = nil)
  UI.message("🔍 Querying Git tags for current version code (group build)...")

  begin
    # Fetch build tags (optimized: only once per build, only build/* tags)
    _smf_fetch_build_tags_once

    # Query all build tags and extract version codes (new + legacy format)
    all_version_codes = sh(
      "{ git tag -l 'build/*/*/*' 2>/dev/null; git tag -l 'build/*/*' 2>/dev/null; } | grep -oE '[0-9]+$' | sort -n | uniq",
      log: false
    ).strip

    if all_version_codes.empty?
      # No tags found - fallback to Config.json
      base_version = @smf_fastlane_config[:app_version_code] || 1
      UI.important("⚠️  No Git tags found, using Config.json: #{base_version}")
      return base_version
    end

    # Get highest version code from all tags (reuse for group build)
    current_version = all_version_codes.split("\n").last.to_i

    UI.message("📊 Current highest versionCode from Git tags: #{current_version}")
    UI.message("🔗 Reusing versionCode for group build: #{current_version}")

    return current_version

  rescue => e
    # Error reading tags - fallback to Config.json
    UI.error("❌ Error reading Git tags: #{e.message}")
    base_version = @smf_fastlane_config[:app_version_code] || 1
    UI.important("⚠️  Falling back to Config.json: #{base_version}")
    return base_version
  end
end

# Private: Fetch build tags from remote (optimized - only once per build)
# Uses caching to avoid multiple fetches in the same pipeline
def _smf_fetch_build_tags_once
  # Use instance variable to cache across function calls
  if @smf_build_tags_fetched.nil?
    UI.message("🔄 Fetching build tags from remote (optimized: only build/* tags)...")
    begin
      # Option 1 + 3: Fetch only build/* tags, only once per build
      sh("git fetch origin 'refs/tags/build/*:refs/tags/build/*' --quiet --force 2>&1 || true")
      @smf_build_tags_fetched = true
      UI.success("✅ Fetched build tags successfully")
    rescue => e
      UI.important("⚠️  Could not fetch tags: #{e.message}")
      UI.important("💡 Continuing with local tags...")
      @smf_build_tags_fetched = true  # Don't retry on error
    end
  else
    UI.message("📦 Using cached build tags (already fetched in this pipeline)")
  end
end
