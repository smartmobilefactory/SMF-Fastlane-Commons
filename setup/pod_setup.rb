ios_setup_file = "#{@fastlane_commons_dir_path}/setup/ios_setup.rb"

if File.exist?(ios_setup_file)
  import(ios_setup_file)
else
  raise "Can't find ios_setup file at #{ios_setup_file}"
end

# Build (Build to Release)

private_lane :smf_super_build_for_pod_pr_check do |options|

  build_variants_for_pr_check = smf_build_variants_for_pod_pr_check
  build_variants_for_pr_check.each { |variant|
    UI.message("Building variant #{variant} for PR Check")
    options[:build_variant] = variant
    smf_build(options)
  }

end

lane :smf_build_for_pod_pr_check do |options|
  smf_super_build_for_pod_pr_check(options)
end