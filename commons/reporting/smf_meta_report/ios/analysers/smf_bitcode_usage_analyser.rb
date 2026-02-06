#!/usr/bin/ruby

# returns the analysed property
# Note (CBENEFIOS-2076): Bitcode was deprecated in Xcode 14 and removed in Xcode 15.
# This check is no longer necessary for modern projects.
# The function now returns 'deprecated' without querying all targets.
def smf_analyse_bitcode(xcode_settings = {}, options = {})
  UI.message("Analyser: #{__method__.to_s} ...")
  UI.message("ℹ️  Bitcode analysis skipped (deprecated since Xcode 14)")

  # Bitcode was deprecated in Xcode 14 (Sept 2022) and removed in Xcode 15
  # No need to iterate through all targets for this obsolete setting
  return 'deprecated (Xcode 14+)'
end
