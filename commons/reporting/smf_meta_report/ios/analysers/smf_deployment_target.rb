#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_deployment_target(xcode_settings)
  UI.message("Analyser: #{__method__.to_s} ...")

  key = 'IPHONEOS_DEPLOYMENT_TARGET'
  deployment_target =  smf_xcodeproj_settings_get(key, xcode_settings)

  if deployment_target.nil?
    raise "[ERROR]: Project does not contain a valid #{key}"
  end

  return deployment_target
end
