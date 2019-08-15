#######################
### smf_publish_pod ###
#######################

desc "Publish the pod. Either to the official specs repo or to the SMF specs repo"
private_lane :smf_publish_pod do |options|

  build_variant = options[:build_variant]

  UI.important("Publishing the Pod")

  # Variables
  bump_type = @smf_bump_type
  branch = @smf_git_branch
  project_config = @smf_fastlane_config[:project]
  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]
  podspec_path = build_variant_config[:podspec_path]
  generateMetaJSON = (build_variant_config[:generateMetaJSON].nil? ? true : build_variant_config[:generateMetaJSON])

  generate_temporary_appfile

  # Unlock keycahin to enable pull repo with https
  if smf_is_keychain_enabled
    unlock_keychain(path: "login.keychain", password: ENV["LOGIN"])
  end

  if smf_is_keychain_enabled
    unlock_keychain(path: "jenkins.keychain", password: ENV["JENKINS"])
  end

  # Make sure the repo is up to date and clean
  ensure_git_branch(branch: branch)

  tag = smf_version_number(podspec_path: podspec_path, bump_type: bump_type)

  # Update the MetaJSONS if wanted
  if generateMetaJSON != false
    begin

      smf_generate_meta_json
      smf_commit_meta_json
    rescue => exception
      UI.important("Warning: MetaJSON couldn't be created")

      smf_send_message(
          title: "Failed to create MetaJSON for #{smf_default_notification_release_title} 😢",
          type: "error",
          exception: exception,
          slack_channel: ci_ios_error_log
      )
      next
    end
  end

  smf_git_changelog(build_variant: build_variant)

  smf_git_pull

  # Push the changes to a temporary branch
  push_to_git_remote(
      remote: 'origin',
      local_branch: branch,
      remote_branch: "jenkins_build/#{branch}",
      force: true,
      tags: true
  )

  begin
    # Publish the pod. Either to a private specs repo or to the offical one
    smf_pod_push

  rescue => e
    # Remove the git tag
    sh "git push --delete origin #{tag} || true"
    # Remove the temporary git branch
    sh "git push origin --delete jenkins_build/#{branch} || true"

    raise "Pod push failed: #{e.message}"
  end

  # Push the changes to the original branch
  push_to_git_remote(
      remote: 'origin',
      local_branch: branch,
      remote_branch: branch,
      force: false,
      tags: true
  )

  # Remove the temporary git branch
  sh "git push origin --delete jenkins_build/#{branch} || true"

  version = read_podspec(path: podspec_path)["version"]

  # Create the GitHub release
  smf_create_github_release(
      release_name: version,
      tag: tag
  )

  smf_send_default_build_success_notification(build_variant: build_variant, name: get_default_name_of_pod(build_variant))
end
