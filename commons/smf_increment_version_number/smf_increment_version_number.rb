private_lane :smf_increment_version_number do |options|

  UI.message('Increment version number')

  podspec_path = options[:podspec_path]
  bump_type = options[:bump_type]

  if !["major", "minor", "patch", "breaking", "internal"].include? bump_type
    raise "The bump type \"#{bump_type}\" should not be used! The buixd job will be aborted."
  end

  # Bump library's version if needed
  bump_pod_version(podspec_path, bump_type)

  version_number = version_get_podspec(path: podspec_path)

  tag = smf_get_tag_of_pod(version_number)

  #  Bump library's version if needed
  count = 0
  while git_tag_exists(tag: tag)
    if count == 10
      raise "The Git tag \"#{tag}\" already exists even after increment it ten times! The build job will be aborted to avoid builds with the same version number. Please check the project!"
    end
    UI.message("The Git tag \"#{tag}\" already exists! The version number will be incremented again.")
    count += 1
    bump_pod_version(podspec_path, bump_type)
    tag = smf_get_tag_of_pod(version_number)
  end

  # Commit version bump if needed
  if ["major", "minor", "patch", "breaking", "internal"].include? bump_type
    git_commit(
        path: podspec_path,
        message: "Release Pod #{version_number}"
    )
  end
  if ["major", "minor", "patch", "breaking", "internal"].include? bump_type
    add_git_tag(tag: tag)
  end
  tag
end

def bump_pod_version(podspec_path, bump_type)
  UI.message("bump pod version: #{bump_type}")
  if ["major", "minor", "patch"].include? bump_type
    version_bump_podspec(
        path: podspec_path,
        bump_type: bump_type
    )
  elsif ["breaking", "internal"].include? bump_type
    # The versionning here is major.minor.breaking.internal
    # major & minor are set manually
    # Only breaking and internal are incremented via Fastlane
    if bump_type == "breaking"
      # Here we need to bump the patch component
      version_bump_podspec(
          path: podspec_path,
          bump_type: "patch"
      )

      # And set back the appendix to 0
      version_bump_podspec(
          path: podspec_path,
          version_appendix: "0"
      )
    elsif bump_type == "internal"
      appendix = 0
      current_version_number_components = version_get_podspec(path: podspec_path).split(".").map(&:to_i)

      appendix = current_version_number_components[3] if current_version_number_components.length >= 4

      appendix = appendix.next

      version_bump_podspec(
          path: podspec_path,
          version_appendix: appendix.to_s
      )
    end
  end
end