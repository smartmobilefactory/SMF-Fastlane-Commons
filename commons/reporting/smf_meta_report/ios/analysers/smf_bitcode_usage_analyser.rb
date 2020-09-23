#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_bitcode
  UI.message("Analyser: #{__method__.to_s} ...")

  pbxproj = smf_pbxproj_file_path
  bitcode_usage = "enabled"

  grab_yes = "#{`fgrep -R "ENABLE_BITCODE = " #{pbxproj} | grep -v "YES;"`}"

  if (grab_yes != "" && grab_yes != nil)
    grab_no = "#{`fgrep -R "ENABLE_BITCODE = " #{pbxproj} | grep -v "NO;"`}"
    if (grab_no != "" && grab_no != nil)
      bitcode_usage = "enabled"
    else
      bitcode_usage = "disabled"
    end
  end

  return bitcode_usage
end
