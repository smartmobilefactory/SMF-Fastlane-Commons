#!/usr/bin/ruby

# returns a tupel describing the status and what the error is
# first tupel entry is the status: OK, WARNING, ERROR
# seconde tupel entry is a message
def smf_analyse_xcode_version()
  UI.message("DEBUG HELLO WORLD")  #debug
  UI.message("Analyser: #{__method__.to_s} ...")
  UI.message("DEBUG #{@smf_fastlane_config}")  #debug
  return @smf_fastlane_config[:project][:xcode_version]
end