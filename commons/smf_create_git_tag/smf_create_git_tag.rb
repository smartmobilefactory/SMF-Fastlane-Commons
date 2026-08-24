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
    next tag
  end
  UI.message("✅ Tag not found locally")

  # Check if tag already exists on remote
  UI.message("🔍 Checking remote tags for '#{tag}'...")
  if _smf_git_tag_exists_on_remote?(tag)
    UI.important("⚠️  Git tag '#{tag}' already exists on remote - skipping tag creation")
    UI.important("💡 This can happen if a previous build with the same version already created this tag")
    next tag
  end
  UI.message("✅ Tag not found on remote")

  add_git_tag(tag: tag)
  UI.success("✅ Created git tag: #{tag}")

  # Pushed here rather than with the rest of the run.
  #
  # The tag reserves a build number and the number goes into the plist, but it is
  # *spent* only when the binary reaches App Store Connect — which happens later.
  # Anything failing in between takes the local tag down with the workspace while
  # the number stays taken at Apple, so the next build computes the same one and
  # is rejected as a duplicate. Pushing on creation closes that window and, since
  # add_git_tag tags the checked-out commit, records which code the number belongs
  # to even for a run that later fails.
  begin
    sh("git push origin 'refs/tags/#{tag}'")
    UI.success("✅ Pushed git tag: #{tag}")
  rescue StandardError => e
    # Not fatal: the build itself is fine and the tag exists locally. Said loudly
    # because the consequence surfaces one build later, somewhere else entirely.
    UI.important("⚠️  Could not push tag '#{tag}': #{e.message}")
    UI.important("💡 The number is reserved locally only — if this run fails after the upload, the next build will reuse it and be rejected")
  end

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