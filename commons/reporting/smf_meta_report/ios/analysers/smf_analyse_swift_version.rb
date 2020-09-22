#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_swift_version()
  UI.message("Analyser: #{__method__.to_s} ...")

  swift_version = nil
  grab = "#{`fgrep -R "SWIFT_VERSION = " #{smf_pbxproj_file_path()}`}"
  grab.split("\n").each do |config|
    # Extract Swift version from each line of the output of fgrep.
    if swift_version_match = config.match("([0-9.]+);$")
      matched_version = swift_version_match.captures
      # Check if the swift version is consistent or not
      if swift_version.nil?
        swift_version = matched_version
      elsif swift_version != matched_version
        raise "[ERROR]: Multiple SWIFT_VERSION were found in the \"project.pbxproj\": '#{swift_version}' and '#{matched_version}'"
      end
    end
  end

  if swift_version.nil?
    UI.important("Project might not contained any Swift code or is not programmed in Swift!")
  end

  swift_version
end
