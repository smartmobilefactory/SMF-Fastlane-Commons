# Platform filtering utilities for cross-platform projects
# CBENEFIOS-2079
#
# Filters commits and tickets based on platform relevance (iOS, Android)
# Uses path-based analysis and Jira component mapping

# Platform constants
PLATFORM_IOS = :ios
PLATFORM_ANDROID = :android
PLATFORM_BOTH = :both
PLATFORM_DEVOPS = :devops
PLATFORM_EXCLUDED = :excluded

# Path patterns for platform detection
PLATFORM_PATH_PATTERNS = {
  PLATFORM_IOS => [
    /^iosApp\//,
    /\.swift$/,
    /\.xcodeproj/,
    /\.xcworkspace/,
    /Podfile/,
    /\.pbxproj$/
  ],
  PLATFORM_ANDROID => [
    /^androidApp\//,
    /\.kt$/,
    /\.java$/,
    /\.gradle$/,
    /AndroidManifest\.xml$/
  ],
  PLATFORM_BOTH => [
    /^shared\//,
    /\.kts$/,          # Kotlin script (often shared build config)
    /gradle\.properties$/
  ],
  PLATFORM_DEVOPS => [
    /^fastlane\//,
    /^\.fastlane/,
    /Fastfile$/,
    /Jenkinsfile$/,
    /^\.github\//,
    /^\.gitlab/,
    /^Config\.json$/,
    /\.yml$/,
    /\.yaml$/
  ],
  PLATFORM_EXCLUDED => [
    /\.md$/,
    /LICENSE/,
    /\.gitignore$/,
    /\.editorconfig$/
  ]
}.freeze

# Jira component to platform mapping
COMPONENT_PLATFORM_MAPPING = {
  'iOS App' => PLATFORM_IOS,
  'Android App' => PLATFORM_ANDROID,
  'KMM Core' => PLATFORM_BOTH,
  'DevOps' => PLATFORM_DEVOPS,
  'Dokumentation' => PLATFORM_EXCLUDED,
  'Design & Konzept' => PLATFORM_EXCLUDED,
  'Infrastruktur' => PLATFORM_DEVOPS,
  'Projektmanagement' => PLATFORM_EXCLUDED,
  'QA' => PLATFORM_BOTH  # QA affects both platforms
}.freeze

# Detect platform from file paths changed in a commit
# @param commit_sha [String] Git commit SHA
# @return [Symbol] Platform constant (:ios, :android, :both, :devops, :excluded)
def smf_detect_platform_from_commit(commit_sha)
  # Get list of files changed in this commit
  files = `git diff-tree --no-commit-id --name-only -r #{commit_sha} 2>/dev/null`.strip.split("\n")

  return PLATFORM_EXCLUDED if files.empty?

  smf_detect_platform_from_paths(files)
end

# Detect platform from a list of file paths
# @param paths [Array<String>] List of file paths
# @return [Symbol] Platform constant
def smf_detect_platform_from_paths(paths)
  return PLATFORM_EXCLUDED if paths.nil? || paths.empty?

  platforms_found = Set.new

  paths.each do |path|
    platform = _smf_match_path_to_platform(path)
    platforms_found.add(platform) unless platform == PLATFORM_EXCLUDED
  end

  # If no relevant platforms found, it's excluded
  return PLATFORM_EXCLUDED if platforms_found.empty?

  # If only DevOps, return DevOps
  return PLATFORM_DEVOPS if platforms_found == Set.new([PLATFORM_DEVOPS])

  # Remove DevOps from consideration for main platform detection
  app_platforms = platforms_found - Set.new([PLATFORM_DEVOPS])

  return PLATFORM_DEVOPS if app_platforms.empty?

  # If both iOS and Android are affected, return both
  return PLATFORM_BOTH if app_platforms.include?(PLATFORM_IOS) && app_platforms.include?(PLATFORM_ANDROID)
  return PLATFORM_BOTH if app_platforms.include?(PLATFORM_BOTH)

  # Return single platform
  return PLATFORM_IOS if app_platforms.include?(PLATFORM_IOS)
  return PLATFORM_ANDROID if app_platforms.include?(PLATFORM_ANDROID)

  PLATFORM_EXCLUDED
end

# Match a single path to its platform
# @param path [String] File path
# @return [Symbol] Platform constant
def _smf_match_path_to_platform(path)
  # Check excluded first
  PLATFORM_PATH_PATTERNS[PLATFORM_EXCLUDED].each do |pattern|
    return PLATFORM_EXCLUDED if path.match?(pattern)
  end

  # Check specific platforms
  [PLATFORM_IOS, PLATFORM_ANDROID, PLATFORM_BOTH, PLATFORM_DEVOPS].each do |platform|
    PLATFORM_PATH_PATTERNS[platform].each do |pattern|
      return platform if path.match?(pattern)
    end
  end

  # Default: if can't determine, assume both platforms might be affected
  PLATFORM_BOTH
end

# Detect platform from Jira components
# @param components [Array<String>] List of Jira component names
# @return [Symbol] Platform constant
def smf_detect_platform_from_components(components)
  return PLATFORM_BOTH if components.nil? || components.empty?

  platforms_found = Set.new

  components.each do |component|
    platform = COMPONENT_PLATFORM_MAPPING[component]
    platforms_found.add(platform) if platform
  end

  return PLATFORM_BOTH if platforms_found.empty?

  # If only DevOps/Excluded, return that
  return PLATFORM_DEVOPS if platforms_found == Set.new([PLATFORM_DEVOPS])
  return PLATFORM_EXCLUDED if platforms_found == Set.new([PLATFORM_EXCLUDED])

  # Remove non-app platforms
  app_platforms = platforms_found - Set.new([PLATFORM_DEVOPS, PLATFORM_EXCLUDED])

  return PLATFORM_DEVOPS if app_platforms.empty? && platforms_found.include?(PLATFORM_DEVOPS)
  return PLATFORM_EXCLUDED if app_platforms.empty?

  # If both iOS and Android, return both
  return PLATFORM_BOTH if app_platforms.include?(PLATFORM_IOS) && app_platforms.include?(PLATFORM_ANDROID)
  return PLATFORM_BOTH if app_platforms.include?(PLATFORM_BOTH)

  # Return single platform
  return PLATFORM_IOS if app_platforms.include?(PLATFORM_IOS)
  return PLATFORM_ANDROID if app_platforms.include?(PLATFORM_ANDROID)

  PLATFORM_BOTH
end

# Check if a platform is relevant for a target build platform
# @param detected_platform [Symbol] The detected platform of a commit/ticket
# @param target_platform [Symbol] The platform being built (:ios or :android)
# @return [Boolean] True if the commit/ticket is relevant
def smf_platform_relevant?(detected_platform, target_platform)
  return false if detected_platform == PLATFORM_EXCLUDED
  return true if detected_platform == PLATFORM_BOTH
  return true if detected_platform == target_platform

  # DevOps is special - it's relevant but handled separately
  # Return false here; DevOps items should be filtered separately
  false
end

# Check if a platform is DevOps-related
# @param detected_platform [Symbol] The detected platform
# @return [Boolean] True if DevOps-related
def smf_platform_is_devops?(detected_platform)
  detected_platform == PLATFORM_DEVOPS
end

# Filter commits by platform
# @param commits [Array<Hash>] Array of commit hashes with :sha and :message keys
# @param target_platform [Symbol] Target platform (:ios or :android)
# @return [Hash] { app_commits: [...], devops_commits: [...] }
def smf_filter_commits_by_platform(commits, target_platform)
  result = {
    app_commits: [],
    devops_commits: []
  }

  return result if commits.nil? || commits.empty?

  commits.each do |commit|
    sha = commit[:sha]
    platform = smf_detect_platform_from_commit(sha)

    if smf_platform_is_devops?(platform)
      result[:devops_commits] << commit
    elsif smf_platform_relevant?(platform, target_platform)
      result[:app_commits] << commit
    end
    # Excluded commits are silently dropped
  end

  result
end

# Get platform symbol from build variant string
# @param build_variant [String] e.g., 'de_alpha', 'germany_beta'
# @return [Symbol] :ios or :android (default: :android for unknown)
def smf_get_platform_from_build_variant(build_variant)
  return PLATFORM_ANDROID if build_variant.nil?

  # This function should be overridden in project-specific Fastfile if needed
  # Default implementation assumes we're building for the current platform context
  # which is set by @platform variable in the Fastfile

  if defined?(@platform)
    case @platform
    when :ios, :apple
      return PLATFORM_IOS
    when :android
      return PLATFORM_ANDROID
    end
  end

  # Default to Android if can't determine
  PLATFORM_ANDROID
end
