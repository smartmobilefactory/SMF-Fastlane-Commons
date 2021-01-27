#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_bitcode(xcode_settings={}, options={})
  UI.message("Analyser: #{__method__.to_s} ...")

  bitcode_configuration =  smf_xcodeproj_settings_get('ENABLE_BITCODE', xcode_settings, options)

  bitcode_usage = 'enabled'
  if (bitcode_configuration == 'NO')
    # bitcode is enabled by default, custom state is disabled
    bitcode_usage = 'disabled'
  end

  return bitcode_usage
end
