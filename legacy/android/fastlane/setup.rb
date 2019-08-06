###########################
######## after_all ########
###########################
after_all do |lane|
  if lane == :releasing_pr_phase || lane == :deploy
    smf_notify_build_success
  end
end

def smf_setup_android_fastlane_commons(options = Hash.new)
  # Import the splitted Fastlane classes
  import_all "#{@fastlane_commons_dir_path}/fastlane/lanes"
end

