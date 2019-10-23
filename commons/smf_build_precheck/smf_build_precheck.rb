private_lane :smf_build_prechek do |options|

	if @platform == :ios
		perform_build_precheck_ios(options[:build_variant], options[:build_variant_config])
	end
end

def perform_build_precheck_ios(build_variant, build_variant_config)

	if build_variant_config[:upload_itc] == true && !build_variant_config[:itc_apple_id].nil?
		UI.error("itc_apple_id not set in Config.json. Please Read: https://smartmobilefactory.atlassian.net/wiki/spaces/SMFIOS/pages/669646876/Missing+itc+apple+id ")
	end
end
