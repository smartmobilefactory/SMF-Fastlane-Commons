fastlane_require 'json'

def load_properties(properties_filename)
  properties = {}
  File.open(properties_filename, 'r') do |properties_file|
    properties_file.read.each_line do |line|
      line.strip!
      if (line[0] != ?# and line[0] != ?=)
        i = line.index('=')
        if (i)
          properties[line[0..i - 1].strip] = line[i + 1..-1].strip
        else
          properties[line] = ''
        end
      end
    end
  end
  properties
end

def load_config()
  load_json("../Config.json")
end

def update_config(config, message = nil)
  jsonString = JSON.pretty_generate(config)
  File.write("#{smf_workspace_dir}/Config.json", jsonString)
  git_add(path: "#{smf_workspace_dir}/Config.json")
  git_commit(path: "#{smf_workspace_dir}/Config.json", message: message || "Update Config.json")
end

def load_json(filename)
  json = nil
  if File.file?(filename)
    json = JSON.parse(File.read(filename))
  end
  json
end

def project_name()
  config = load_config()
  project_name = ENV["PROJECT_NAME"]
  if config
    project_name = config["project"]["name"]
  end
  project_name
end
