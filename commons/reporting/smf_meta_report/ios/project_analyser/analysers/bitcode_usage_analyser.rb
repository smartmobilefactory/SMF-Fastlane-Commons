#!/usr/bin/ruby

require_relative '../../../helper/logger.rb'
require_relative '../../../helper/project_configuration_reader.rb'

module BitcodeUsage

  KEY = 'bitcode_enabled'

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification(src_root)
    analysis_file = analysis_file_path(src_root)

    if analysis_file == nil
      return :ERROR, "Error reading project name from project Config.json, name is needed for path construction."
    end

    if FileHelper::file_exists(analysis_file) == false
      return :ERROR, "Error project has no \"project.pbxproj\" file which is needed for the anlysis"
    end

    return :OK
  end

  # returns the analysed property
  def self.analyse(src_root)
    Logger::info("Analysing #{self.to_s} ...")
    analysis_file = FileHelper::escape_path(analysis_file_path(src_root))
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

  def self.analysis_file_path(src_root)
    project_name =`cd #{src_root} && ls | grep -E "(\s|.)+\.xcodeproj"`

    if project_name == nil
      return nil
    end

    project_name = project_name.split("\n")[0]

    analysis_file = File.join(File.expand_path(src_root), project_name.gsub("\n", ""), "project.pbxproj")
    return analysis_file
  end
end