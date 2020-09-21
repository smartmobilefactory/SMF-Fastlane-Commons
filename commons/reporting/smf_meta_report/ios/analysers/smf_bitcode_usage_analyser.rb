#!/usr/bin/ruby

require 'fileutils'

def _smf_bitcode_analyser_verification()
  analysis_file = _smf_bitcode_analyser_file_path(smf_workspace_dir)

  if analysis_file == nil
    raise "Error reading project name from project Config.json, name is needed for path construction."
  end

  if File.file?(analysis_file) == false
    # file? will only return true for files; false for directories
    raise "Error project has no \"project.pbxproj\" file which is needed for the anlysis"
  end
end

# returns the analysed property
def smf_analyse_bitcode()
  src_root = smf_workspace_dir
  UI.message("Analyser: #{__method__.to_s} ...")
  _smf_bitcode_analyser_verification()
  UI.message("bitcode verified #{__method__.to_s} ...")
  analysis_file = _smf_bitcode_analyser_escape_path(_smf_bitcode_analyser_file_path(src_root))
  bitcode_usage = "enabled"

  grab_yes = "#{`fgrep -R "ENABLE_BITCODE = " #{analysis_file} | grep -v "YES;"`}"

  if (grab_yes != "" && grab_yes != nil)
    grab_no = "#{`fgrep -R "ENABLE_BITCODE = " #{analysis_file} | grep -v "NO;"`}"
    if (grab_no != "" && grab_no != nil)
      bitcode_usage = "enabled"
    else
      bitcode_usage = "disabled"
    end
  end

  return bitcode_usage
end

def _smf_bitcode_analyser_file_path(src_root)
  project_name =`cd #{src_root} && ls | grep -E "(\s|.)+\.xcodeproj"`

  if project_name == nil
    return nil
  end

  project_name = project_name.split("\n")[0]

  analysis_file = File.join(File.expand_path(src_root), project_name.gsub("\n", ""), "project.pbxproj")
  return analysis_file
end

def _smf_bitcode_analyser_escape_path(path)
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