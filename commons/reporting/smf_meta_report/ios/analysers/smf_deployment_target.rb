#!/usr/bin/ruby

# returns the analysed property
# Optimized (CBENEFIOS-2076): Only checks iOS deployment target by default
# to avoid unnecessary xcodebuild calls for platforms not used by the project.
# Pass platforms: [:ios, :macos, :tvos, :watchos] to check specific platforms.
def smf_analyse_deployment_targets(xcode_settings = {}, options = {}, platforms = nil)
  UI.message("Analyser: #{__method__.to_s} ...")

  all_keys = {
    ios: { name: 'iOS', key: 'IPHONEOS_DEPLOYMENT_TARGET' },
    macos: { name: 'macOS', key: 'MACOSX_DEPLOYMENT_TARGET' },
    tvos: { name: 'tvOS', key: 'TVOS_DEPLOYMENT_TARGET' },
    watchos: { name: 'watchOS', key: 'WATCHOS_DEPLOYMENT_TARGET' }
  }

  # Default to iOS only for most projects (optimization)
  # Full check can be triggered by passing platforms: [:ios, :macos, :tvos, :watchos]
  platforms_to_check = platforms || [:ios]

  deployment_targets_string = ''

  platforms_to_check.each do |platform|
    platform_info = all_keys[platform]
    next unless platform_info

    deployment_target = smf_xcodeproj_settings_get(platform_info[:key], xcode_settings, options)

    if !deployment_target.nil? && deployment_target != ''
      prefix = (deployment_targets_string == '' ? '' : ', ')
      deployment_targets_string += "#{prefix}#{platform_info[:name]} #{deployment_target}"
    end
  end

  return deployment_targets_string
end
