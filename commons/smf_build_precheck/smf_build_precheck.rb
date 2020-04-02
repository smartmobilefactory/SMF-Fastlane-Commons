private_lane :smf_build_precheck do |options|

  upload_itc = options[:upload_itc]
  itc_apple_id = options[:itc_apple_id]
  pods_spec_repo = options[:pods_spec_repo]

  case @platform
  when :ios
    _check_common_project_setup_files
    perform_build_precheck_ios(upload_itc, itc_apple_id)
    perform_build_precheck_for_pods_spec_repo_url(
      pods_spec_repo
    )
  when :ios_framework
    _check_common_project_setup_files
    perform_build_precheck_for_pods_spec_repo_url(
      pods_spec_repo
    )
  when :macos
    _check_common_project_setup_files
  when :flutter
    perform_build_precheck_ios(upload_itc, itc_apple_id)
  else
    UI.message("Build Precheck: Nothing reportable found")
  end
end

def _check_common_project_setup_files
  submodule_directory = File.join(smf_workspace_dir, 'Submodules/SMF-iOS-CommonProjectSetupFiles')

  current_head_commit = `cd #{submodule_directory}; git rev-parse HEAD`.gsub("\n", '')
  remote_head_commit = `cd #{submodule_directory}; git rev-parse origin/master`.gsub("\n", '')

  ENV['DANGER_COMMON_PROJECT_SETUP_FILES_OUTDATED'] = 'true' unless current_head_commit == remote_head_commit
end

def perform_build_precheck_ios(upload_itc, itc_apple_id)

  if upload_itc == true && itc_apple_id.nil?
    message = 'itc_apple_id not set in Config.json. Please Read: https://smartmobilefactory.atlassian.net/wiki/spaces/SMFIOS/pages/669646876/Missing+itc+apple+id '

    smf_send_message(
      title: 'Build Precheck Error',
      message: message,
      type: 'error'
    )

    raise message
  else
    UI.message("Build Precheck: Nothing reportable found")
  end
end

def perform_build_precheck_for_pods_spec_repo_url(pods_specs_repo = false)

  podfile = @platform == :flutter ? "#{smf_workspace_dir}/ios/Podfile" : "#{smf_workspace_dir}/Podfile"
  podfile_content = File.read(podfile)
  https_in_podfile = !podfile_content.match(/source 'https:\/\/github\.com\/smartmobilefactory\/SMF-CocoaPods-Specs'/m).nil?
  https_in_config = pods_specs_repo == 'https://github.com/smartmobilefactory/SMF-CocoaPods-Specs'

  if https_in_podfile || https_in_config
    prefix_podfile = https_in_podfile ? 'in the Podfile' : ''
    prefix_config = https_in_config ? 'in the Config.json' : ''
    connector = https_in_podfile && https_in_config ? ' and ' : ''

    message = "⛔️ The HTTPS podspec repo url is still present #{prefix_podfile}#{connector}#{prefix_config}. Please update to use the ssh url. See https://smartmobilefactory.atlassian.net/wiki/spaces/SMFIOS/pages/674201953/Wrong+cocoapods+repo+in... for more information"

    UI.error(message)

    smf_send_message(
      title: 'Build Precheck Error',
      message: message,
      type: 'error'
    )

    smf_create_pull_request_comment(
      comment: message
    )

    raise "Podspec repo is an https url"
  end
end
