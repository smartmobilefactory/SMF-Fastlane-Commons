private_lane :smf_create_github_release do |options|

  build_variant = options[:build_variant]
  build_number = options[:build_number]
  tag = options[:tag]
  paths = !options[:paths].nil? ? options[:paths] : []
  branch = options[:branch]
  changelog = options[:changelog]

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

   if changelog.nil?
     UI.error("Changelog is nil, using default string.")
     changelog = "No description (changelog) provided."
   end

  version = smf_get_version_number(build_variant: build_variant)
  release_name = "#{build_variant.upcase} #{version} (#{build_number})"

  if @platform == :ios_framework
    release_name = "#{smf_get_version_number(podspec_path: podspec_path)}"
  end

    # Create the GitHub release as draft
  release = set_github_release(
      is_draft: true,
      repository_name: repository_path,
      api_token: ENV[$SMF_GITHUB_TOKEN_ENV_KEY],
      name: release_name,
      tag_name: tag,
      description: changelog,
      commitish: branch,
      upload_assets: paths
  )

  release_id = release['id']
  UI.message("Found id \"#{release_id}\" for release \"#{tag}\"")

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