private_lane :smf_create_git_tag do |options|

  build_variant = options[:build_variant]
  build_number = options[:build_number]

  tag = smf_get_tag_of_app(build_variant, build_number)

  # Check if tag already exists locally (CBENEFIOS-2074)
  if git_tag_exists(tag: tag)
    UI.important("⚠️  Git tag '#{tag}' already exists locally - skipping tag creation")
    UI.important("💡 This can happen if a previous build with the same version already created this tag")
    return tag
  end

  # Check if tag already exists on remote
  if git_tag_exists(tag: tag, remote: true)
    UI.important("⚠️  Git tag '#{tag}' already exists on remote - skipping tag creation")
    UI.important("💡 This can happen if a previous build with the same version already created this tag")
    return tag
  end

  add_git_tag(tag: tag)
  UI.success("✅ Created git tag: #{tag}")

  tag
end