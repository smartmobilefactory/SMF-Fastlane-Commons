private_lane :smf_increment_version_number do |options|

  podspec_path = options[:podspec_path]
  bump_type = options[:bump_type]

  UI.message('Incrementing version number') unless bump_type == 'current'

  # Bump library's version if needed
  _smf_bump_pod_version(podspec_path, bump_type)

  version_number = smf_get_version_number(nil, podspec_path)
  tag = smf_get_tag_of_pod(podspec_path)

  if git_tag_exists(tag: tag)
    raise "⛔️ The new tag ('#{tag}') already exists! Aborting..."
  end

  if bump_type != 'current'
    git_commit(
        path: podspec_path,
        message: "Release Pod #{version_number}"
    )
  end

  add_git_tag(tag: tag)

  tag
end

private_lane :smf_increment_version_number_dry_run do |options|
  podspec_path = options[:podspec_path]
  bump_type = options[:bump_type]

  version_number = _smf_bump_pod_version(podspec_path, bump_type, true)

  version_number
end

def _smf_bump_pod_version(podspec_path, bump_type, dry_run = false)
  UI.message("Increasing pod version: #{bump_type}") unless bump_type == 'current'

  if ['major', 'minor', 'patch'].include? bump_type
    version_bump_podspec(
        path: podspec_path,
        bump_type: bump_type
    )

  elsif ['breaking', 'internal'].include? bump_type
    # The versioning here is major.minor.breaking.internal
    # major & minor are set manually
    # Only breaking and internal are incremented via Fastlane
    if bump_type == "breaking"
      # Here we need to bump the patch component
      # # And set back the appendix to 0
      version_bump_podspec(
          path: podspec_path,
          bump_type: 'patch'
      )

      version_bump_podspec(
        path: podspec_path,
        version_appendix: '0'
      )

    elsif bump_type == 'internal'
      appendix = 0
      currentVersionNumberComponents = version_get_podspec(path: podspec_path).split('.').map(&:to_i)

      if currentVersionNumberComponents.length >= 4
        appendix = currentVersionNumberComponents[3]
      end

      appendix = appendix.next

      version_bump_podspec(
          path: podspec_path,
          version_appendix: appendix.to_s
      )
    end
  end



  # if we only want to get the new version which would be commited if
  # we actually ran bump_pod_version
  if dry_run
    version_number = smf_get_version_number(nil, podspec_path)
    sh("cd #{smf_workspace_dir} && git checkout #{podspec_path}")
  end

  version_number
end