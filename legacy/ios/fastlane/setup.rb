#################
### Lifecycle ###
#################

def smf_setup_ios_fastlane_commons(options = Hash.new)
  UI.message("Starting ios fastlane commons setup")
  puts "Fastlane dir: #{@fastlane_commons_dir_path}"
  # Import the splitted Fastlane classes
  import_all "#{@fastlane_commons_dir_path}/fastlane/flow"
  import_all "#{@fastlane_commons_dir_path}/fastlane/steps"
  import_all "#{@fastlane_commons_dir_path}/fastlane/utils"
  UI.message("Got til 1")
  # Setup build type options
  smf_setup_default_build_type_values

  UI.message("Got til 2")

  # Override build type options by inline
  build_type = options[:build_type]
  smf_override_build_type_options_by_type(build_type)
  UI.message("got til 3")
  @smf_original_platform = ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY]
  puts "Original Platform #{@smf_original_platform}"
end

##############
### Helper ###
##############

def import_all(path)
  Dir["#{path}/*.rb"].each { |file|
    import file
  }
end

##############
### Config ###
##############

def smf_value_for_keypath_in_hash_map(hash_map, keypath)
  keys = keypath.split("/")
  value = hash_map
  for key in keys
    if value.key?(key.to_sym)
      value = value[key.to_sym]
    else
      raise "Error: Couldn't find keypath \"#{keypath}\" in \"#{hash_map}\""
    end
  end
  return value
end

def smf_set_should_send_deploy_notifications(should_notify)
  @smf_set_should_send_deploy_notifications = should_notify
end

def smf_set_should_send_build_job_failure_notifications(should_notify)
  @smf_set_should_send_build_job_failure_notifications = should_notify
end

def smf_set_build_variant(build_variant, reset_build_variant_array = true)
  @smf_build_variant = build_variant.downcase
  @smf_build_variant_sym = @smf_build_variant.to_sym
  if reset_build_variant_array
    smf_set_build_variants_array(nil)
  end

  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]

  if build_variant_config == nil
    raise "Error: build variant \"#{@smf_build_variant}\" isn't declared in the configuration file."
  end

  # Override build type options if set in Config.json
  smf_override_build_type_options_by_variant_config(build_variant_config)

  # Modify the platform if needed
  platform = build_variant_config[:platform]
  if platform != nil
    # Change the platform to the declared one
    ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY] = platform
  else
    # Reset the platform to one which was active in "befor_all" if no platform is specified
    ENV[$FASTLANE_PLATFORM_NAME_ENV_KEY] = @smf_original_platform
  end
end

def smf_set_build_variants_array(build_variants)
  @smf_build_variants_array = build_variants
end

def smf_set_build_variants_matching_regex(regex)
  all_build_variants = @smf_fastlane_config[:build_variants].keys
  matching_build_variants = all_build_variants.grep(/#{regex}/).map(&:to_s)

  UI.important("Found matching build variants: #{matching_build_variants}")

  smf_set_build_variants_array(matching_build_variants)
end

def smf_set_bump_type(bump_type)
  @smf_bump_type = bump_type
end

def smf_set_git_branch(branch)
  @smf_git_branch = branch
end

#####################################################
### Helper (needed without commons repo available)###
#####################################################

def smf_setup_default_build_type_values
  smf_set_slack_enabled(true)
  smf_set_keychain_enabled(true)
end

def smf_override_build_type_options_by_variant_config(build_variant_config)
  is_slack_enabled = (build_variant_config[:slack_enabled].nil? ? smf_is_slack_enabled : build_variant_config[:slack_enabled])
  is_keychain_enabled = (build_variant_config[:keychain_enabled].nil? ? smf_is_keychain_enabled : build_variant_config[:keychain_enabled])

  puts "Overriding build type options:\n slack_enabled: #{is_slack_enabled}\n keychain_enabled: #{is_keychain_enabled}"

  smf_set_slack_enabled(is_slack_enabled)
  smf_set_keychain_enabled(is_keychain_enabled)
end

def smf_override_build_type_options_by_type(build_type)
  if not build_type.nil?
    puts "Overriding build type options with build type: #{build_type}"
    if build_type == "local"
      smf_set_keychain_enabled(false)
    elsif build_type == "quiet"
      smf_set_slack_enabled(false)
    elsif build_type == "develop"
      smf_set_slack_enabled(false)
      smf_set_keychain_enabled(false)
    end
  end
end

def smf_is_jenkins_environment
  return ENV["JENKINS_URL"]
end

def smf_set_slack_enabled(value)
  newValue = value ? "true" : "false"
  return ENV[$SMF_IS_SLACK_ENABLED] = newValue
end

def smf_is_slack_enabled
  return ENV[$SMF_IS_SLACK_ENABLED].nil? ? true : ENV[$SMF_IS_SLACK_ENABLED] == "true"
end

def smf_set_keychain_enabled(value)
  newValue = value ? "true" : "false"
  return ENV[$SMF_IS_KEYCHAIN_ENABLED] = newValue
end

def smf_is_keychain_enabled
  return ENV[$SMF_IS_KEYCHAIN_ENABLED].nil? ? true : ENV[$SMF_IS_KEYCHAIN_ENABLED] == "true"
end

def ci_ios_error_log
  return "#{$SMF_CI_IOS_ERROR_LOG}"
end

def slack_url
  return "#{$SMF_SLACK_URL}"
end
