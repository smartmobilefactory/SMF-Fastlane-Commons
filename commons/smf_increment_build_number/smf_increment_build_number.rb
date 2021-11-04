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

  last_tag = sh("git describe --tags --match \"build/*/*\" `git rev-list --tags --max-count=1` --abbrev=0 || echo #{NO_GIT_TAG_FAILURE}").to_s

  # Use build number of the project if there is no matching tag yet
  if last_tag.include? NO_GIT_TAG_FAILURE
    build_number = current_build_number
    UI.message("build number from project: #{build_number}")
  else
    parts = last_tag.split('/')
    count = parts.count
    build_number = parts[count - 1]

    if build_number.include? '.'
      parts = build_number.split('.')
      parts[0]
    end
    UI.message("build number from last tag: #{build_number}")
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

    commit_version_bump(
      xcodeproj: smf_get_xcodeproj_file_name,
      message: "Increment build number to #{build_number}",
      force: true
    )
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