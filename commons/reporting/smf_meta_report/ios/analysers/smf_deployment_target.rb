#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_deployment_targets(xcode_settings, options)
  UI.message("Analyser: #{__method__.to_s} ...")

  keys = {
    :iphoneos_deployment_target => 'IPHONEOS_DEPLOYMENT_TARGET',
    :macosx_deployment_target => 'MACOSX_DEPLOYMENT_TARGET',
    :tvos_deployment_target => 'TVOS_DEPLOYMENT_TARGET',
    :watchos_deployment_target => 'WATCHOS_DEPLOYMENT_TARGET'
  }

  analysis_json = {}

  keys.each do |key, config|
    deployment_target = smf_xcodeproj_settings_get(config, xcode_settings, options)
    analysis_json[key] = deployment_target
  end

  return analysis_json
end
