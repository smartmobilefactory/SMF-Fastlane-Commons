#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_bitcode(xcode_settings)
  UI.message("Analyser: #{__method__.to_s} ...")

  buildSettings = xcode_settings[0].dig('buildSettings')
  bitcode_configuration = buildSettings.dig('ENABLE_BITCODE')

  bitcode_usage = 'enabled'
  if (bitcode_configuration == 'NO')
    # bitcode is enabled by default
    # custom state is disabled
    bitcode_usage = 'disabled'
  end

  return bitcode_usage
end
