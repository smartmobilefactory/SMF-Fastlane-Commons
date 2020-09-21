#!/usr/bin/ruby

require_relative '../../../helper/logger.rb'
require_relative '../../../helper/project_configuration_reader.rb'

module ProgrammingLanguage

  KEY = 'programming_language'

  def self.verification(src_root)
    return ProjectConfigurationReader::verify_project_property(src_root, 'programming_language')
    end

  def self.analyse(src_root)
    Logger::info("Analysing #{self.to_s} ...")
    return ProjectConfigurationReader::read_project_property(src_root, 'programming_language')
  end
end