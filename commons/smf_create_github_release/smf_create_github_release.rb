private_lane :smf_create_github_release do |options|

  build_variant = options[:build_variant]
  build_number = options[:build_number]
  tag = options[:tag]
  paths = !options[:paths].nil? ? options[:paths] : []
  branch = options[:branch]
  changelog = options[:changelog]
  podspec_path = options[:podspec_path]

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

  version = smf_get_version_number(build_variant, podspec_path)
  release_name = "#{build_variant.upcase} #{version} (#{build_number})"

  if @platform == :ios_framework
    release_name = "#{smf_get_version_number(nil, podspec_path)}"
  end

  # Set inside the begin block and read by the rescue, so the draft can be taken
  # back if publishing it fails.
  release_id = nil

  begin
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
  rescue => e
    raise e unless e.message.include?('already_exists') || e.message.include?('422')

    UI.important("⚠️  GitHub release for tag '#{tag}' already exists — skipping")

    # A draft carries no git tag, so creating one never collides and this only
    # ever fails on the publish. Without the cleanup the draft stays: thirty
    # identical drafts had collected on one repository, one per build, each
    # reported as "skipping" — which reads as "nothing was done".
    _smf_delete_github_release(repository_path, release_id) unless release_id.nil?
  end
end

def _smf_delete_github_release(repository_path, release_id)
  github_api(
      server_url: 'https://api.github.com',
      api_token: ENV[$SMF_GITHUB_TOKEN_ENV_KEY],
      http_method: 'DELETE',
      path: "/repos/#{repository_path}/releases/#{release_id}"
  )
  UI.message("Removed the draft that could not be published (id #{release_id}).")
rescue => e
  # Worth saying, not worth failing the build over: the release itself is
  # already lost at this point and a leftover draft is litter, not damage.
  UI.important("⚠️  Could not remove draft #{release_id}: #{e.message}")
end

def zipped_path(path)
  if File.exist?(path)
    if File.extname(path) != '.zip'
      zipped_file_path = "#{path}.zip"
      sh "cd \"#{File.dirname(path)}\"; zip -r -q \"#{zipped_file_path}\" \"./#{File.basename(path)}\""
      File.path(zipped_file_path)
    else
      File.path(path)
    end
  end
end