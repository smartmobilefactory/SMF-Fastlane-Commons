private_lane :smf_build_number do |options|

  UI.important('increment build number')

  build_variant = options[:build_variant]
  NO_GIT_TAG_FAILURE = 'NO_GIT_TAG_FAILURE'

  # Pull all the tags so the change log collector finds the latest tag
  UI.message('Fetching all tags...')
  sh('git fetch --tags --quiet')

  last_tag = sh("git describe --tags --match \"build/*/*\" --abbrev=0 HEAD --first-parent || echo #{NO_GIT_TAG_FAILURE}").to_s

  # Use build number of the project if there is no matching tag yet
  if last_tag.include? NO_GIT_TAG_FAILURE
    build_number = get_build_number_of_app
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

  current_build_number = get_build_number_of_app

  unless current_build_number.nil?
    if incremented_build_number.to_i < (current_build_number.to_i + 1)
      incremented_build_number = (current_build_number + 1).to_s
      UI.message("The project's build number is greater than the fetched build number. The incremented build number is now: #{incremented_build_number}")
    end
  end

  smf_update_build_number_in_project(incremented_build_number)

  tag = get_tag_of_app(build_variant, incremented_build_number)

  count = 0
  while git_tag_exists(tag: tag)
    if count == 10
      raise "The Git tag \"#{tag}\" already exists! The build job will be aborted to avoid builds with the same build number."
    end
    UI.message("The Git tag \"#{tag}\" already exists! The build number will be incremented again.")
    count += 1
    incremented_build_number = (incremented_build_number.to_i + 1).to_s
    smf_update_build_number_in_project(incremented_build_number)
    UI.message("Incremented build number: #{incremented_build_number}")
    tag = get_tag_of_app(build_variant, incremented_build_number)
  end

  add_git_tag(tag: tag)

  tag
end


def smf_update_build_number_in_project(build_number)
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
