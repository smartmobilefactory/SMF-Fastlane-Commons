OWNER = "smartmobilefactory"
REPO = "SMF-Sparkle-Packages-Container"

lane :smf_create_sparkle_package do |options|
  UI.message("Starting sparkle package creator...")

  UI.message("Input file is at: #{options[:dmg_path]}")
  build_variant = !options[:build_variant].nil? ? options[:build_variant] : smf_get_first_variant_from_config
  build_variant_config = @smf_fastlane_config[:build_variants][build_variant.to_sym]
  sparkle_config = build_variant_config[:sparkle]
  input_dmg_path = File.join(smf_workspace_dir, options[:dmg_path])
  target_directory = File.join(smf_workspace_dir, "sparkle_package/")
  project_name = @smf_fastlane_config[:project][:project_name]
  build_number = smf_get_build_number_of_app

  if sparkle_config.nil?
    UI.error("There is no sparkle entry for the build variant: #{build_variant}")
    raise "Missing sparkle entry in Config.json"
  end

  unless Dir.exist?(target_directory)
    Dir.mkdir(target_directory)
  end

  sh("cp #{input_dmg_path} #{File.join(target_directory, File.basename(input_dmg_path))}")
  input_dmg_path = File.join(target_directory, File.basename(input_dmg_path))

  smf_upload_with_sparkle(
    build_variant: build_variant,
    scheme: build_variant_config[:scheme],
    sparkle_version: sparkle_config[:sparkle_version],
    sparkle_signing_team: sparkle_config[:sparkle_signing_team],
    sparkle_private_key: sparkle_config[:signing_key],
    source_dmg_path: input_dmg_path,
    target_directory: target_directory,
  )
  package_name = _smf_sparkle_package_name(project_name, build_variant, build_number)
  package_path = _smf_zip_sparkle_package(target_directory, package_name)

  #_smf_create_github_release_and_upload_asset(package_path, project_name, build_variant, build_number)
end



# "CONSTANTS"
def _smf_spc_template_path
  "#{@fastlane_commons_dir_path}/commons/smf_generate_jenkins_file/Jenkinsfile_Sparkle_Package_Creator.template"
end

def _smf_spc_jenkinsfile_path
  File.join(smf_workspace_dir,'Sparkle-Package-Creator/Sparkle-Package-Creator-Jenkinsfile')
end

def _smf_sparkle_package_name(project_name, build_variant, build_number)
  "#{project_name}-#{build_variant}-#{build_number}"
end

def _smf_create_github_release_and_upload_asset(asset_path, project_name, build_variant, build_number)

  tag = "#{project_name}/#{build_variant}/#{build_number}"
  release_name = _smf_sparkle_package_name(project_name, build_variant, build_number)
  description = ''

  release = {
    "tag_name" => tag,
    "target_commitish" => "master",
    "name" => release_name,
    "body" => description,
    "draft" => false,
    "prerelease" => false
  }


  release_data = JSON.generate(release)
  request_url = "https://api.github.com/repos/#{OWNER}/#{REPO}/releases"
  UI.message("Creating release...")
  response_data = `curl -X POST #{request_url} -H "Content-Type:application/json" -H "Authorization: token #{ENV[$SMF_GITHUB_TOKEN_ENV_KEY]}" -d #{release_data.dump}`

  response = JSON.parse(response_data, symbolize_names: true)

  UI.message("Response: #{response}")

  if response.nil?
    error_message = "An error occured creating the relase"
    UI.error(error_message)
    raise error_message
  elsif !response[:message].nil?
    error_message = "Error creating the release: #{response[:message]}"
    UI.error(error_message)
    raise error_message
  end

  release_id = response[:id]
  assets_url = "https://uploads.github.com/repos/#{OWNER}/#{REPO}/releases/#{release_id}/assets?name=#{File.basename(asset_path)}"
  UI.message("Attaching sparkle package to release ...")
  response_data = `curl -X POST #{assets_url} --data-binary @"#{asset_path}" -H "Authorization: token #{ENV[$SMF_GITHUB_TOKEN_ENV_KEY]}" -H "Content-Type: application/octet-stream"`
  response = JSON.parse(response_data, symbolize_names: true)
  UI.message("Response: #{response}")
  if response.nil?
    error_message = "An error occured uploading the asset"
    UI.error(error_message)
    raise error_message
  elsif !response[:message].nil?
    error_message = "Error creating the release: #{response[:message]} #{response[:errors]}"
    UI.error(error_message)
    raise error_message
  end
end

def _smf_zip_sparkle_package(path, name)
  zipped_file_path = File.join(File.dirname(path), "#{name}.zip")
  sh("cd \"#{File.dirname(path)}\"; zip -r -q \"#{zipped_file_path}\" \"./#{File.basename(path)}\"")

  zipped_file_path
end