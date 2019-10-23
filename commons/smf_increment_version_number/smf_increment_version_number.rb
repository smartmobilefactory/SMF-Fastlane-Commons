private_lane :smf_increment_version_number do |options|

  UI.message('Incrementing version number')

  podspec_path = options[:podspec_path]
  bump_type = options[:bump_type]

  # Bump library's version if needed
  _smf_bump_pod_version(podspec_path, bump_type)

  tag = smf_get_tag_of_pod(podspec_path)

  if git_tag_exists(tag: tag)
    raise "⛔️ The new tag ('#{tag}') already exists! Aborting..."
  end

  git_commit(
      path: podspec_path,
      message: "Release Pod #{version_number}"
  )

  add_git_tag(tag: tag)

  tag
end

def _smf_bump_pod_version(podspec_path, bump_type)
  UI.message("Increasing pod version: #{bump_type}")

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
      # # And set back the appendix to 0
      version_bump_podspec(
          path: podspec_path,
          bump_type: "patch",
          version_appendix: "0"
      )

    elsif bump_type == "internal"
      appendix = 0
      currentVersionNumberComponents = version_get_podspec(path: podspec_path).split(".").map(&:to_i)

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
end