#!/usr/bin/ruby

require 'fileutils'

require_relative 'logger.rb'
require_relative 'json_reader.rb'

module ProjectConfigurationReader

  PROJECT_CONFIG_FILE = "Config.json"

  def self.verify_project_property(src_root, property)
    config = JsonReader::read(config_path(src_root))

    if config == nil
      return :ERROR, "Error reading project Config.json, " + config_path(src_root) + " does not exist."
    elsif config['project'][property] == nil
      return :WARNING, "Error reading property \"#{property}\" in projects Config.json"
    end

    return :OK
  end

  def self.read_project_property(src_root, property)
    config = JsonReader::read(config_path(src_root))
    if config != nil
      return config['project'][property]
    end

    return nil
  end

  def self.config_path(src_root)
    return File.join(File.expand_path(src_root), ProjectConfigurationReader::PROJECT_CONFIG_FILE)
  end

end