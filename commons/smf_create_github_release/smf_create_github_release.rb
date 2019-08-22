private_lane :smf_create_github_release do |options|

  build_variant = options[:build_variant]
  release_name = options[:release_name]
  tag = options[:tag]

  git_remote_origin_url = sh 'git config --get remote.origin.url'
  github_url_match = git_remote_origin_url.match(%r{.*github.com:(.*)\.git})

  # Search fot the https url if the ssh url couldn't be found
  github_url_match = git_remote_origin_url.match(%r{.*github.com/(.*)\.git}) if github_url_match.nil?

  if github_url_match.nil? || (github_url_match.length < 2)
    UI.message("The remote origin doesn't seem to be GitHub. The GitHub Release won't be created.")
    return
  end

  repository_path = github_url_match[1]

  UI.message("Found \"#{repository_path}\" as GitHub project.")

  paths_to_simulator_builds = []

  if should_attach_build_outputs_to_github(build_variant)
    # Zip the release build
    # Upload dmg instead of app if Sparkle is enabled
    path_to_ipa_or_app = get_path_to_ipa_or_app(build_variant)
    ipa_or_app_filename = File.basename(path_to_ipa_or_app)
    ipa_or_app_directory_path = File.dirname(path_to_ipa_or_app)
    sh "cd \"#{ipa_or_app_directory_path}\"; zip -r \"#{$SMF_DEVICE_RELEASE_APP_ZIP_FILENAME}\" \"#{ipa_or_app_filename}\""

    paths_to_simulator_builds = ["#{ipa_or_app_directory_path}/#{$SMF_DEVICE_RELEASE_APP_ZIP_FILENAME}", "#{smf_workspace_dir}/build/#{$SMF_SIMULATOR_RELEASE_APP_ZIP_FILENAME}"]
  end

  paths_to_simulator_builds += smf_add_app_to_git_tag(build_variant)
  UI.message("Path to attach: #{paths_to_simulator_builds}")

  # Create the GitHub release as draft
  set_github_release(
      is_draft: true,
      repository_name: repository_path,
      api_token: ENV[$SMF_GITHUB_TOKEN_ENV_KEY],
      name: release_name.to_s,
      tag_name: tag,
      description: ENV[$SMF_CHANGELOG_ENV_KEY],
      commitish: @smf_git_branch,
      upload_assets: paths_to_simulator_builds
  )

  release_id = smf_get_github_release_id_for_tag(tag, repository_path)

  # Publish the release. We do this after the release was created as the assets are uploaded after the release is created on Github which results in release webhooks which doesn't contain the assets!
  github_api(
      server_url: 'https://api.github.com',
      api_token: ENV[$SMF_GITHUB_TOKEN_ENV_KEY],
      http_method: 'PATCH',
      path: "/repos/#{repository_path}/releases/#{release_id}",
      body: {
          "draft": false
      }
  )
end

def smf_add_app_to_git_tag(build_variant)
  path_to_files_to_attach = []
  if get_platform(build_variant) == 'mac'
    UI.message('Adding .app file and test folder to project.')

    path_to_ipa_or_app = get_path_to_ipa_or_app(build_variant)

    # check if the path is actually pointing to the .app file
    if File.extname(path_to_ipa_or_app) != '.app'
      if File.extname(path_to_ipa_or_app) == '.zip' && File.extname(path_to_ipa_or_app.gsub('.zip', '')) == '.app'
        sh "unzip -o #{path_to_ipa_or_app}"
        path_to_ipa_or_app = path_to_ipa_or_app.gsub('.zip', '')
      else
        UI.message("Couldn't find .app file, can't attach App to github release")
        next
      end
    end

    path_to_renamed_app_file = File.join(File.dirname(path_to_ipa_or_app), "#{get_project_name}.app")
    sh "cp -r #{path_to_ipa_or_app} #{path_to_renamed_app_file}"
    path_to_files_to_attach.append(path_to_renamed_app_file)

    test_dir = File.join(smf_workspace_dir, 'Tests/SMFTests')
    if File.exist?(test_dir)
      test_dir_zipped = "#{test_dir}.zip"
      sh "zip -r \"#{test_dir_zipped}\" \"#{test_dir}\""
      path_to_files_to_attach.append(test_dir_zipped)
    end
  end
  path_to_files_to_attach
end

def smf_get_github_release_id_for_tag(tag, repository_path)

  result = github_api(
      server_url: 'https://api.github.com',
      api_token: ENV[$SMF_GITHUB_TOKEN_ENV_KEY],
      http_method: 'GET',
      path: "/repos/#{repository_path}/releases"
  )

  releases = JSON.parse(result[:body])
  release_id = nil
  releases.each do |release|
    if release['tag_name'] == tag
      release_id = release['id']
      break
    end
  end

  UI.message("Found id \"#{release_id}\" for release \"#{tag}\"")

  release_id
end