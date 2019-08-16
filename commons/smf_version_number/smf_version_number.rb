private_lane :smf_version_number do |options|

  UI.message('Increment version number')

  podspec_path = options[:podspec_path]
  bump_type = options[:bump_type]

  # Bump the pods version if needed
  bump_pod_verison(podspec_path, bump_type)

  UI.message("version_get_podspec: #{version_get_podspec(path: podspec_path)}")

  version_number = get_version_number
  UI.message("version_number: #{version_number}")

  tag = get_tag_of_pod(version_number)

  # Check if the New Tag already exists
  smf_git_tag_exists(tag: tag)

  version = read_podspec(path: podspec_path)["version"]
  UI.message("version_number: #{version}")
  # Commit the version bump if needed
  if ["major", "minor", "patch", "breaking", "internal"].include? bump_type
    git_commit(
        path: podspec_path,
        message: "Release Pod #{version}"
    )
  end

  smf_add_git_tag(tag: tag)

  tag
end

def bump_pod_verison(podspec_path, bump_type)
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