#!/usr/bin/ruby

require_relative '../../../helper/logger.rb'
require_relative '../../../helper/project_configuration_reader.rb'

module XcodeVersion

  KEY = 'xcode_version'

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification(src_root)
    return ProjectConfigurationReader::verify_project_property(src_root, 'xcode_version')
  end

  def self.analyse(src_root)
    Logger::info("Analysing #{self.to_s} ...")
    return ProjectConfigurationReader::read_project_property(src_root, 'xcode_version')
  end
end