#!/usr/bin/ruby

require 'fileutils'
require 'json'

# TODO: use already loaded config.json

module ProjectConfigurationReader

  PROJECT_CONFIG_FILE = "Config.json"

  def self.read_JSON(path)

    if File.exist?(path)

      json_from_config = File.read(path)
      config_json = JSON.parse(json_from_config)

      return config_json
    end

    return nil
  end


  def self.verify_project_property(src_root, property)
    config = ProjectConfigurationReader::read_JSON(config_path(src_root))

    if config == nil
      return :ERROR, "Error reading project Config.json, " + config_path(src_root) + " does not exist."
    elsif config['project'][property] == nil
      return :WARNING, "Error reading property \"#{property}\" in projects Config.json"
    end

    return :OK
  end

  def self.read_project_property(src_root, property)
    config = ProjectConfigurationReader::read_JSON(config_path(src_root))
    if config != nil
      return config['project'][property]
    end

    return nil
  end

  def self.config_path(src_root)
    return File.join(File.expand_path(src_root), ProjectConfigurationReader::PROJECT_CONFIG_FILE)
  end

end