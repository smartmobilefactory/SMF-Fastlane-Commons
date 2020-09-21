#!/usr/bin/ruby

require_relative '../../../helper/logger.rb'

module Idfa

  KEY = 'idfa'
  FILES_TO_IGNORE = ["BITHockeyManager.h", "create-project-json.sh"]
  DIR_TO_IGNORE = [".xcarchive", "MetaJSON-Wrapper.app"]
  @file_candidates = []

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification(src_root)

    if File.exist?(src_root) == false
      return :ERROR, "Error the projects root directory (\"#{src_root}\") does not exist"
    end

    return :OK
  end

  # returns the analysed property
  def self.analyse(src_root)
    Logger::info("Analysing #{self.to_s} ...")

    idfa_usage = "disabled"
    idfa_appearances = []
    file_candidates = `fgrep -R advertisingIdentifier #{src_root} #{self.ignore_files_string} || echo "error"`

    if file_candidates == "error\n"
      return {"usage" => idfa_usage, "appearances" => idfa_appearances}
    else
      file_candidates = file_candidates.split("\n")
    end

    file_candidates.each do |line|
      matches = line.match(/Binary file (.+)\smatches$/)
      if matches != nil
        occourance = matches.captures[0].gsub("#{src_root}", "")
        if idfa_appearances.include?(occourance) == false
          idfa_appearances.push(occourance)
        end
      else
        matches = line.match(/[^:]+/)
        if matches != nil
          occourance = matches[0].gsub(":", "").gsub("#{src_root}", "").gsub("Binary file ", "")
          if idfa_appearances.include?(occourance) == false
            idfa_appearances.push(occourance)
          end 
        end
      end
    end

    if idfa_appearances.length > 0
      idfa_usage = "custom"
    end

    return {"usage" => idfa_usage, "appearances" => idfa_appearances}
  end

  def self.ignore_files_string
    result = ""
    FILES_TO_IGNORE.each do |file|
      result = result + "--exclude #{file} "
    end

    DIR_TO_IGNORE.each do |dir|
      result = result + "--exclude-dir #{dir} "
    end

    return result
  end
end