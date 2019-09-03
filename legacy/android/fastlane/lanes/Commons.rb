fastlane_require 'json'

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
