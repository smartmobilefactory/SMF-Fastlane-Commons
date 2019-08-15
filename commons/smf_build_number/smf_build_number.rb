private_lane :smf_build_number do |options|

  UI.important('increment build number')

  build_variant = options[:build_variant]
  NO_GIT_TAG_FAILURE = 'NO_GIT_TAG_FAILURE'

  # Pull all the tags so the change log collector finds the latest tag
  UI.message('Fetching all tags...')
  sh('git fetch --tags --quiet')

  last_tag = sh("git describe --tags --abbrev=0 HEAD --first-parent || echo #{NO_GIT_TAG_FAILURE}").to_s

  # Use build number of the project if there is no matching tag yet
  if last_tag.include? NO_GIT_TAG_FAILURE
    build_number = get_build_number_of_app
  else
    matching_pattern = %r{build/.*/.*}
    if last_tag =~ matching_pattern
      parts = last_tag.split('/')
      count = parts.count
      build_number = parts[count - 1]
      UI.message("build number from the last tag: #{build_number}")
    else
      build_number = get_build_number_of_app
      UI.message("build number from the project: #{build_number}")
    end
  end

  incremented_build_number = (build_number.to_i + 1).to_s
  UI.message("Incremented build number: #{incremented_build_number}")

  current_build_number = get_build_number_of_app

  unless current_build_number.nil?
    if incremented_build_number.to_i < current_build_number.to_i
      incremented_build_number = (current_build_number + 1).to_s
      UI.message("The project's build number is greater than the build number from last tag. The incremented build number is now: #{incremented_build_number}")
    end
  end
  smf_update_build_number_in_project(incremented_build_number)

  tag = get_tag_of_app(build_variant, incremented_build_number)

  # check if git tag exists
  smf_git_tag_exists(tag: tag)

  smf_add_git_tag(tag: tag)

  tag
end


def smf_update_build_number_in_project(build_number)
  UI.message("Update build number to: #{build_number}")
  case @platform
  when :ios
    increment_build_number(build_number: build_number.to_s)
  when :android
    @smf_fastlane_config["app_version_code"] = build_number.to_i
    update_config(@smf_fastlane_config, "Increment build number to #{@smf_fastlane_config["app_version_code"]}")
    new_app_version_code = @smf_fastlane_config["app_version_code"].to_s
    # keep environment variable to be compatible
    ENV["next_version_code"] = new_app_version_code
  when :flutter
    UI.message('increment build number for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end
end

def get_tag_of_app(build_variant, build_number)
  "build/#{build_variant.downcase}/#{build_number}"
end
