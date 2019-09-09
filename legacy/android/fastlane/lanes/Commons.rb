fastlane_require 'json'

def load_config()
  load_json("../Config.json")
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
