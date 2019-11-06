private_lane :smf_build_precheck do |options|

  upload_itc = options[:upload_itc]
  itc_apple_id = options[:itc_apple_id]

	case @platform
 	when :ios, :flutter
		perform_build_precheck_ios(upload_itc, itc_apple_id)
  when :ios_framework
    perform_build_precheck_ios_frameworks(
        options[:pod_spec_repo],
        options[:pull_request_number]
    )
	else
		UI.message("Build Precheck: Nothing reportable found")
	end
end

def perform_build_precheck_ios(upload_itc, itc_apple_id)

	if upload_itc == true && itc_apple_id.nil?
		message = "itc_apple_id not set in Config.json. Please Read: https://smartmobilefactory.atlassian.net/wiki/spaces/SMFIOS/pages/669646876/Missing+itc+apple+id "

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

def perform_build_precheck_ios_frameworks(pods_specs_repo, pull_request_number)
	podfile = "#{smf_workspace_dir}/Podfile"
	podfile_content = File.read(podfile)
	https_in_podfile = !podfile_content.match(/source 'https:\/\/github\.com\/smartmobilefactory\/SMF-CocoaPods-Specs'/m).nil?
	https_in_config = pods_specs_repo == 'https://github.com/smartmobilefactory/SMF-CocoaPods-Specs'

	if https_in_podfile || https_in_config
		prefix_podfile = https_in_podfile ? 'in the Podfile' : ''
		prefix_config = https_in_config ? 'in the Config.json' : ''
		connector = https_in_podfile && https_in_config ? ' and ' : ''

		log_msg = "The https podspec repo url is still present #{prefix_podfile}#{connector}#{prefix_config}. See https://smartmobilefactory.atlassian.net/wiki/spaces/SMFIOS/pages/674201953/Wrong+cocoapods+repo+in... for more information"

		UI.error(log_msg)

		# Try to post a comment on the PR

		git_remote_origin_url = sh 'git config --get remote.origin.url'
		matcher = git_remote_origin_url.match(/github\.com(:|\/)(.+)\/(.+)\.git/)

		UI.message("DEBUGGING: git repo urls is: #{git_remote_origin_url} and matcher is: #{matcher}")
		UI.message("DEBUGGING: captures are: #{matcher.captures}")

		if !matcher.nil?
			if !matcher.captures.nil? && matcher.captures.count == 3
				repo_owner = matcher.captures[1]
				repo_name = matcher.captures[2]

				UI.message("DEBUGGING; repo_owner: #{repo_owner}, repo_name: #{repo_name}, github_token is nil: #{ENV["GITHUB_TOKEN"].nil?}")

				UI.message("Posting error as pr comment!")

				sh("curl -H \"Authorization: token #{ENV["GITHUB_TOKEN"]}\" -d '{\"body\": \"#{log_msg}\"}' -X POST https://api.github.com/repos/#{repo_owner}/#{repo_name}/issues/#{pull_request_number}/comments")
			end
		end

		raise "Pospec repo is an https url"
	end
end
