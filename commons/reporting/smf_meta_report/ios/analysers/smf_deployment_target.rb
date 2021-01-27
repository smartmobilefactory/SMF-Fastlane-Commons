#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_deployment_targets(xcode_settings, options)
  UI.message("Analyser: #{__method__.to_s} ...")

  keys = {
    'iOS' => 'IPHONEOS_DEPLOYMENT_TARGET',
    'macOS' => 'MACOSX_DEPLOYMENT_TARGET',
    'tvOS' => 'TVOS_DEPLOYMENT_TARGET',
    'watchOS' => 'WATCHOS_DEPLOYMENT_TARGET'
  }

  deployment_targets = ''

  keys.each do |key, config|
    deployment_target = smf_xcodeproj_settings_get(config, xcode_settings, options)
    if !deployment_target.nil?
        prefix = (deployment_target == '' ? '' : ' ')
        deployment_targets = "#{prefix}#{key} #{deployment_target}"
    end
  end

  return deployment_targets
end
