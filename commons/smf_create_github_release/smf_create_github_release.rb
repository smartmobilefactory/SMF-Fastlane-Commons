private_lane :smf_create_github_release do |options|

  release_name = options[:release_name]
  tag = options[:tag]
  paths = !options[:paths].nil? ? options[:paths] : []
  branch = options[:branch]

  git_remote_origin_url = sh 'git config --get remote.origin.url'
  github_url_match = git_remote_origin_url.match(%r{.*github.com:(.*)\.git})

  # Search fot the https url if the ssh url couldn't be found
  github_url_match = git_remote_origin_url.match(%r{.*github.com/(.*)\.git}) if github_url_match.nil?

  if github_url_match.nil? || (github_url_match.length < 2)
    UI.message("The remote origin doesn't seem to be GitHub. The GitHub Release won't be created.")
    next
  end

  repository_path = github_url_match[1]
  UI.message("Found \"#{repository_path}\" as GitHub project.")

  #Zip paths if needed
  paths = paths.map do |path|
    zipped_path(path)
  end

  UI.message("Paths to attach: #{paths}")

  # Create the GitHub release as draft
  set_github_release(
      is_draft: true,
      repository_name: repository_path,
      api_token: ENV[$SMF_GITHUB_TOKEN_ENV_KEY],
      name: release_name.to_s,
      tag_name: tag,
      description: ENV[$SMF_CHANGELOG_ENV_KEY],
      commitish: branch,
      upload_assets: paths
  )

  release_id = smf_get_github_release_id_for_tag(tag, repository_path)

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

def zipped_path(path)
  if File.exists?(path)
    if File.extname(path) != '.zip'
      zipped_file_path = "#{File.path(path).gsub(%r{\..*}, '')}.zip"
      sh "cd \"#{File.dirname(path)}\"; zip -r \"#{zipped_file_path}\" \"./#{File.basename(path)}\""
      File.path(zipped_file_path)
    else
      File.path(path)
    end
  end
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