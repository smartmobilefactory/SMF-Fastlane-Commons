#!/usr/bin/ruby

require 'fileutils'

# Returns an escaped path to the xcodeproj
def smf_xcodeproj_file_path
  project_name =`cd #{smf_workspace_dir} && ls | grep -E "(\s|.)+\.xcodeproj"`.strip()

  if project_name.nil?
    raise "Error project has no \".xcodeproj\" which is needed for the anlysis"
  end

  xcodeproj_path = File.join(File.expand_path(smf_workspace_dir), project_name)

  return xcodeproj_path
end


# Returns an escaped path to the pbxproj
def smf_pbxproj_file_path
  project_name =`cd #{smf_workspace_dir} && ls | grep -E "(\s|.)+\.xcodeproj"`

  if project_name.nil?
    raise "Error project has no \".xcodeproj\" which is needed for the anlysis"
  end

  project_name = project_name.split("\n")[0]

  pbxproj_path = File.join(File.expand_path(smf_workspace_dir), project_name.gsub("\n", ""), "project.pbxproj")
  if pbxproj_path.nil? || File.file?(pbxproj_path) == false
    raise "Error project has no \"project.pbxproj\" file which is needed for the anlysis"
  end

  return pbxproj_path
end
