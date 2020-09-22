#!/usr/bin/ruby

# returns the analysed property
def smf_analyse_swift_version()
  UI.message("Analyser: #{__method__.to_s} ...")

  swift_versions = []
  grab = "#{`fgrep -R "SWIFT_VERSION = " #{smf_pbxproj_file_path()}`}"
  grab.split("\n").each do |config|
    if swift_version_match = config.match("([0-9.]+);$")
      swift_version = swift_version_match.captures
      swift_versions.push(swift_version) unless swift_versions.include?(swift_version)
    end
  end

  if swift_versions.count == 0
    UI.important("Project is not a programmed in Swift!")
    return nil
  elsif swift_versions.count > 1
    raise "[ERROR]: Multiple SWIFT_VERSION were found in the \"project.pbxproj\" file: #{swift_versions}"
  else
    return swift_versions[0]
  end
end
