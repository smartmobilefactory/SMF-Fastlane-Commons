private_lane :smf_build_number do |options|

  UI.important('increment build number')

  build_variant = options[:build_variant]
  NO_GIT_TAG_FAILURE = 'NO_GIT_TAG_FAILURE'

  # Pull all the tags so the change log collector finds the latest tag
  UI.message('Fetching all tags...')
  sh('git fetch --tags --quiet')

  last_tag = sh("git describe --tags --abbrev=0 HEAD --first-parent || echo #{NO_GIT_TAG_FAILURE}").to_s

  # Use the initial commit if there is no matching tag yet
  if last_tag.include? NO_GIT_TAG_FAILURE
    incremented_build_number = 1
  else
    app_matching_pattern = 'build/.*/.*'
    pod_matching_pattern = 'release/.*'
    if app_matching_pattern.match?(last_tag) || pod_matching_pattern.match?(last_tag)
      UI.message('Get the build number from the last tag.')
      parts = last_tag.split('/')
      count = parts.count
      build_number = parts[count - 1]
    else
      UI.message('Get the build number from the project.')
      build_number = get_build_number_of_project
      UI.message('test 1')
    end

    if build_number.include? '.'
      parts = build_number.split('.')
      count = parts.count
      incremented_part = (parts[count - 1].to_i + 1).to_s
      prefix = ''
      for i in 0..count - 2
        prefix += "#{parts[i]}."
      end

      incremented_build_number = prefix + incremented_part
    else
      incremented_build_number = (build_number.to_i + 1).to_s
    end
  end

  UI.message('test 2')
  smf_update_build_number_in_project(incremented_build_number)
  UI.message('test 3')
  if @smf_fastlane_config.key?("build_variants")
    tag = !@smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path].nil? ? get_tag_of_pod(incremented_build_number) : get_tag_of_app(build_variant, incremented_build_number)
  else
    tag = get_tag_of_app(build_variant, incremented_build_number)
  end

  UI.message('test 4')
  # check if git tag exists
  smf_git_tag_exists(tag: tag)

  UI.message('test 5')
  smf_add_git_tag(tag: tag)
  UI.message('test 6')
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

