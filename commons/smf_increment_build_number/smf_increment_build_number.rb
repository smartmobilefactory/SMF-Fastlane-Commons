private_lane :smf_increment_build_number do |options|

  UI.important('Incrementing build number ...')

  current_build_number = options[:current_build_number]
  skip_update_in_plists = options[:skip_build_nr_update_in_plists]

  if skip_update_in_plists == true
    UI.message('Will not update build number in projects .plists files')
  end

  NO_GIT_TAG_FAILURE = 'NO_GIT_TAG_FAILURE'

  # Pull all the tags so the change log collector finds the latest tag
  UI.message('Fetching all tags...')
  sh("git fetch --tags --quiet || echo #{NO_GIT_TAG_FAILURE}")

  # The highest number among all build tags, not the number of the newest tag:
  # build tags may carry a version segment (build/<platform>/<variant>/<version>/<number>,
  # RWCIT-2130), and tags written by hand for builds from another numbering space,
  # such as Xcode Cloud, can be newer than the shared counter yet far below it.
  build_number = sh("git tag -l 'build/*' | grep -oE '/[0-9]+$' | tr -d '/' | sort -n | tail -1", log: false).to_s.strip

  # Use build number of the project if there is no matching tag yet
  if build_number.empty?
    build_number = current_build_number
    UI.message("build number from project: #{build_number}")
  else
    UI.message("build number from build tags: #{build_number}")
  end

  incremented_build_number = (build_number.to_i + 1).to_s
  UI.message("Incremented build number: #{incremented_build_number}")

  unless current_build_number.nil?
    if incremented_build_number.to_i < (current_build_number.to_i + 1)
      incremented_build_number = (current_build_number.to_i + 1).to_s
      UI.message("The project's build number is greater than the fetched build number. The incremented build number is now: #{incremented_build_number}.")
    end
  end

  _smf_update_build_number_in_project(incremented_build_number, skip_update_in_plists)
end


def _smf_update_build_number_in_project(build_number, skip_update_in_plists)
  case @platform
  when :ios, :ios_framework, :macos, :apple

    increment_build_number(
    	build_number: build_number.to_s,
      skip_info_plist: skip_update_in_plists
    )

    # Skip commit in CI (CBENEFIOS-1899)
    # CI: Plist files are updated for the build but not committed (similar to Xcode Cloud)
    # Local: Commit changes for local development workflow
    unless smf_is_ci?
      UI.message("🖥️  Local Build - committing plist changes")
      commit_version_bump(
        xcodeproj: smf_get_xcodeproj_file_name,
        message: "Increment build number to #{build_number}",
        force: true
      )
    else
      UI.message("🔢 CI Build - skipping plist commit (changes applied to build only)")
      UI.message("   Build will use number #{build_number}, but plists won't be committed")
    end
  when :android
    new_config = @smf_fastlane_config
    new_config[:app_version_code] = build_number.to_i
    smf_update_config(
      new_config,
      "Increment build number to #{build_number}")
  when :flutter
    pubspec_path = "#{smf_workspace_dir}/pubspec.yaml"
    pubspec = File.read(pubspec_path)
    version = pubspec.scan(/version:.*/).first
    new_version = "#{version.split('+').first}+#{build_number}"
    pubspec = pubspec.gsub(version, new_version)
    File.write(pubspec_path, pubspec)
    git_add(path: pubspec_path)
    git_commit(path: pubspec_path, message: "Increment build number to #{build_number}")
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end