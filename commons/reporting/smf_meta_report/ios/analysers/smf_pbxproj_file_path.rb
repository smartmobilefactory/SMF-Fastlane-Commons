#!/usr/bin/ruby

require 'fileutils'


# Returns path to the xcodeproj, nil if it doesn't exist
def smf_xcodeproj_file_path

  xcodeproj_path = File.join(
    File.expand_path(smf_workspace_dir),
    smf_get_xcodeproj_file_name
  )

  return nil unless File.exist?(xcodeproj_path)

  xcodeproj_path
end


# Returns an escaped path to the pbxproj, nil if it doesn't exist
def smf_pbxproj_file_path

  pbxproj_path = File.join(
    File.expand_path(smf_workspace_dir),
    smf_get_xcodeproj_file_name, "project.pbxproj"
  )

  return nil unless File.file?(pbxproj_path)

  pbxproj_path
end
