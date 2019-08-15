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
    build_number = get_build_number_of_project
  else
    app_matching_pattern = %r{build/.*/.*}
    pod_matching_pattern = %r{release/.*}
    if last_tag =~ app_matching_pattern || last_tag =~ pod_matching_pattern
      parts = last_tag.split('/')
      count = parts.count
      build_number = parts[count - 1]
      UI.message("build number from the last tag: #{build_number}")
    else
      build_number = get_build_number_of_project
      UI.message("build number from the project: #{build_number}")
    end
  end

  if build_number.include? '.'
    parts = build_number.split('.')
    incremented_build_number = (parts[0].to_i + 1).to_s
  else
    incremented_build_number = (build_number.to_i + 1).to_s
  end
  UI.message("Incremented build number: #{incremented_build_number}")

  current_build_number = get_build_number_of_project
  unless current_build_number.nil?
    if incremented_build_number < current_build_number
      incremented_build_number = (current_build_number + 1).to_s
      UI.message("The project's build number is greater than the build number from last tag. The incremented build number is now: #{incremented_build_number}")
    end
  end

  smf_update_build_number_in_project(incremented_build_number)

  if @smf_fastlane_config.key?("build_variants")
    tag = !@smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path].nil? ? get_tag_of_pod(incremented_build_number) : get_tag_of_app(build_variant, incremented_build_number)
  else
    tag = get_tag_of_app(build_variant, incremented_build_number)
  end

  # check if git tag exists
  smf_git_tag_exists(tag: tag)

  smf_add_git_tag(tag: tag)

  tag
end


def smf_update_build_number_in_project(build_number)
  UI.message('Update build number.')
  case @platform
  when :ios
    if @smf_fastlane_config.key?("build_variants")
      !@smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path].nil? ? version_bump_podspec(version_number: build_number) : increment_build_number(build_number: build_number)
    else
      increment_build_number(build_number: build_number)
    end
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

