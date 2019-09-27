private_lane :smf_increment_build_number do |options|

  UI.important('increment build number')

  current_build_number = options[:current_build_number]
  NO_GIT_TAG_FAILURE = 'NO_GIT_TAG_FAILURE'

  # Pull all the tags so the change log collector finds the latest tag
  UI.message('Fetching all tags...')
  sh('git fetch --tags --quiet')

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

  _smf_update_build_number_in_project(incremented_build_number)
end


def _smf_update_build_number_in_project(build_number)
  case @platform
  when :ios
    increment_build_number(build_number: build_number.to_s)
    commit_version_bump(
        xcodeproj: "#{smf_get_project_name}.xcodeproj",
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
    pubspec = YAML.load(File.read("#{smf_workspace_dir}/pubspec.yaml"))
    pubspec['version'] = pubspec['version'].split('+').first + build_number.to_s
    File.open("#{smf_workspace_dir}/pubspec.yaml", 'w') { |f| YAML.dump(pubspec, f) }
    pubspec = YAML.load(File.read("#{smf_workspace_dir}/pubspec.yaml"))
    UI.message("updated version: #{pubspec['version']}")
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end