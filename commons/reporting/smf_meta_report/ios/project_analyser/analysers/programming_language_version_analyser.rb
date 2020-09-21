#!/usr/bin/ruby

require_relative '../../../helper/project_configuration_reader.rb'

module ProgrammingLanguageVersion

  KEY = 'programming_language_version'

  def self.verification(src_root)
    return ProjectConfigurationReader::verify_project_property(src_root, 'programming_language_version')
  end

  def self.analyse(src_root)
    UI.message("Analysing #{self.to_s} ...")
    return ProjectConfigurationReader::read_project_property(src_root, 'programming_language_version')
  end
end