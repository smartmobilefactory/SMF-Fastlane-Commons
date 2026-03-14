private_lane :smf_create_git_tag do |options|

  build_variant = options[:build_variant]
  build_number = options[:build_number]
  platform = options[:platform]

  tag = smf_get_tag_of_app(build_variant, build_number, platform)

  # Check if tag already exists locally
  UI.message("🔍 Checking local tags for '#{tag}'...")
  if _smf_git_tag_exists_locally?(tag)
    UI.important("⚠️  Git tag '#{tag}' already exists locally - skipping tag creation")
    UI.important("💡 This can happen if a previous build with the same version already created this tag")
    return tag
  end
  UI.message("✅ Tag not found locally")

  # Check if tag already exists on remote
  UI.message("🔍 Checking remote tags for '#{tag}'...")
  if _smf_git_tag_exists_on_remote?(tag)
    UI.important("⚠️  Git tag '#{tag}' already exists on remote - skipping tag creation")
    UI.important("💡 This can happen if a previous build with the same version already created this tag")
    return tag
  end
  UI.message("✅ Tag not found on remote")

  add_git_tag(tag: tag)
  UI.success("✅ Created git tag: #{tag}")

  tag
end

# Private: Check if a git tag exists locally (no warnings on missing tag)
def _smf_git_tag_exists_locally?(tag)
  result = sh("git tag -l '#{tag}'", log: false).strip
  !result.empty?
end

# Private: Check if a git tag exists on remote (no warnings on missing tag)
def _smf_git_tag_exists_on_remote?(tag)
  result = sh("git ls-remote --tags origin 'refs/tags/#{tag}'", log: false).strip
  !result.empty?
rescue => e
  UI.important("⚠️  Could not check remote tag (continuing): #{e.message}")
  false
end