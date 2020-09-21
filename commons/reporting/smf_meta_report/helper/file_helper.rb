#!/usr/bin/ruby

require 'fileutils'

require_relative 'logger.rb'

module FileHelper

  def self.remove_dir(path)
    Logger::info("Deleting #{path}")
    if File.exists?(path)
      FileUtils.rm_r(path)
    end
  end

  def self.remove_file(path)
    if File.exist?(path)
      File.delete(path)
    end
  end

  def self.create_parent_dir(path)
    dirname = File.dirname(path)
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
  end

  def self.create_write(path, content)
    self.create_parent_dir(path)
    File.open(path, "w") {|f| 
      f.write(content) 
    }
  end

  def self.file_exists(path)
    escaped_path = self.escape_path(path)
    exists = `if [[ -f #{escaped_path} ]]; then echo "true"; else echo "false"; fi`.gsub("\n", "")
    return exists == "true"
  end

  def self.escape_path(path)
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

  def self.file_content(path)
    begin
      return File.read(path)
    rescue 
      Logger::error("Error reading file: #{path}")
      return nil
    end
  end
end