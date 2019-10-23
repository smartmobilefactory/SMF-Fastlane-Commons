private_lane :smf_build_precheck do |options|

	if @platform == :ios
		perform_build_precheck_ios(options[:build_variant], options[:build_variant_config])
	end
end

def perform_build_precheck_ios(build_variant, build_variant_config)

	if build_variant_config[:upload_itc] == true && build_variant_config[:itc_apple_id].nil?
		raise ITCAppleIdError, "itc_apple_id not set in Config.json. Please Read: https://smartmobilefactory.atlassian.net/wiki/spaces/SMFIOS/pages/669646876/Missing+itc+apple+id "
	else
		UI.message("Build Precheck: Nothing reportable found")
	end
end

class ITCAppleIdError < StandardError
end
