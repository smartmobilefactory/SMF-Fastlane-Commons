###########################
######## after_all ########
###########################
after_all do |lane, options|
  if lane == :releasing_pr_phase || lane == :deploy
    branch = options[:branch]
    smf_push_to_git_remote(branch: branch)
    smf_send_default_build_success_notification(build_variant: ENV['BUILD_VARIANT'], name: get_default_name_of_app(ENV['BUILD_VARIANT']))
  end
end

def smf_setup_android_fastlane_commons(options = Hash.new)
  # Import the splitted Fastlane classes
  import_all "#{@fastlane_commons_dir_path}/fastlane/lanes"
end

def ci_android_error_log
  $SMF_CI_ANDROID_ERROR_LOG.to_s
end

