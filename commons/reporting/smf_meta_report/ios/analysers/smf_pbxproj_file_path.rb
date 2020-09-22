#!/usr/bin/ruby

require 'fileutils'

# Returns an escaped path to the pbxproj
def smf_pbxproj_file_path()
  project_name =`cd #{smf_workspace_dir} && ls | grep -E "(\s|.)+\.xcodeproj"`

  if project_name.nil?
    raise "Error project has no \".xcodeproj\" which is needed for the anlysis"
  end

  project_name = project_name.split("\n")[0]

  pbxproj_path = File.join(File.expand_path(smf_workspace_dir), project_name.gsub("\n", ""), "project.pbxproj")
  if pbxproj_path.nil? || File.file?(pbxproj_path) == false
    raise "Error project has no \"project.pbxproj\" file which is needed for the anlysis"
  end

  return _smf_pbxproj_file_escape_path(pbxproj_path)
end

def _smf_pbxproj_file_escape_path(path)
  escaped_path = path.gsub("\"", "")
  regex = /\/([^\/]+\s+[^\/]+)\//
  result = escaped_path.match(regex)
  if result != nil && result.captures[0] != nil
    escaped_path = escaped_path.gsub(result.captures[0], "\"#{result.captures[0]}\"")
  else
    return path
  end

  return escaped_path
end