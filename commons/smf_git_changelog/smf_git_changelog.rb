#############################
### smf_git_changelog ###
#############################

desc 'Collect git commit messages into a changelog and store as environment variable.'
private_lane :smf_git_changelog do |options|

  build_variant = options[:build_variant].downcase if !options[:build_variant].nil?
  is_library = !options[:is_library].nil? ? options[:is_library] : false

  # Platform filtering (CBENEFIOS-2079)
  # Detect target platform from @platform variable or build_variant
  target_platform = nil
  if defined?(@platform)
    case @platform
    when :ios, :apple
      target_platform = :ios
    when :android
      target_platform = :android
    end
  end
  UI.message("Platform filtering: #{target_platform || 'disabled'}")

  UI.important('Collecting commits back to the last tag')

  # Constants
  NO_GIT_TAG_FAILURE = 'NO_GIT_TAG_FAILURE'

  # Pull all the tags so the change log collector finds the latest tag
  UI.message('Fetching all tags...')
  sh("git fetch --tags --quiet || echo #{NO_GIT_TAG_FAILURE}")

  if is_library
    last_tag = sh("git describe --tags --match \"releases/*\" --abbrev=0 HEAD --first-parent || echo #{NO_GIT_TAG_FAILURE}").to_s
  else
    last_tag = sh("git describe --tags --match \"*#{build_variant}*\" --abbrev=0 HEAD --first-parent || echo #{NO_GIT_TAG_FAILURE}").to_s
  end

  # Use the initial commit if there is no matching tag yet
  if last_tag.include? NO_GIT_TAG_FAILURE
    last_tag = sh('git rev-list --max-parents=0 HEAD').to_s
  end

  last_tag = last_tag.strip

  UI.important("Using tag: #{last_tag} to compare with HEAD")

  # Get commits with SHA for platform filtering (CBENEFIOS-2079)
  commit_data = _smf_get_commits_with_sha(last_tag, 'HEAD')

  # Filter commits by platform if platform filtering is enabled
  app_commits = []
  devops_commits = []

  if target_platform && defined?(smf_detect_platform_from_commit)
    UI.message("Filtering commits for platform: #{target_platform}")

    commit_data.each do |commit|
      platform = smf_detect_platform_from_commit(commit[:sha])

      if platform == :devops
        devops_commits << commit
      elsif platform == :excluded
        UI.message("Excluding commit (docs/config): #{commit[:message][0..50]}...")
      elsif platform == :both || platform == target_platform
        app_commits << commit
      else
        UI.message("Excluding commit (#{platform} only): #{commit[:message][0..50]}...")
      end
    end

    UI.message("Commits after filtering: #{app_commits.length} app, #{devops_commits.length} devops")
  else
    # No platform filtering - all commits are app commits
    app_commits = commit_data
  end

  # Process app commits for changelog
  cleaned_changelog_messages = []
  ignored_commits = [/Release Pod.*/, /Increment build number.*/, /Updating i18n/, /Updated strings from Phrase/]

  app_commits.each do |commit|
    commit_message = "- #{commit[:message]}"

    if _smf_should_commit_be_ignored_in_changelog(commit_message, ignored_commits)
      next
    end

    # Remove the author and use uppercase at line starts for non internal builds
    commit_message = commit_message.sub(/^- \([^\)]*\) /, '- ')
    letters = commit_message.split('')
    letters[2] = letters[2].upcase if letters.length >= 2
    commit_message = letters.join('')
    cleaned_changelog_messages.push(commit_message)
  end

  # Process devops commits separately (CBENEFIOS-2079)
  devops_changelog_messages = []
  devops_commits.each do |commit|
    commit_message = "- #{commit[:message]}"
    next if _smf_should_commit_be_ignored_in_changelog(commit_message, ignored_commits)

    commit_message = commit_message.sub(/^- \([^\)]*\) /, '- ')
    letters = commit_message.split('')
    letters[2] = letters[2].upcase if letters.length >= 2
    commit_message = letters.join('')
    devops_changelog_messages.push(commit_message)
  end

  # Extract related Jira issues info (with platform filtering)
  ticket_tags = smf_get_ticket_tags_from_changelog(cleaned_changelog_messages.uniq)
  devops_ticket_tags = smf_get_ticket_tags_from_changelog(devops_changelog_messages.uniq)

  UI.message("Jira tickets found: #{ticket_tags.length} app, #{devops_ticket_tags.length} devops")

  tickets = smf_generate_tickets_from_tags(ticket_tags, target_platform: target_platform)
  devops_tickets = smf_generate_tickets_from_tags(devops_ticket_tags, target_platform: nil)

  # Merge devops tickets into main tickets structure
  tickets[:devops] = (tickets[:devops] || []) + (devops_tickets[:normal] || []) + (devops_tickets[:devops] || [])
  tickets[:devops].uniq! { |t| t[:tag] }

  # Limit the size of changelog as it's crashes if it's too long
  changelog = cleaned_changelog_messages.uniq.join("\n")
  changelog = "#{changelog[0..20_000]}#{'\\n...'}" if changelog.length > 20_000
  changelog = changelog.split("\n")

  # Convert changelog to different output formats
  html_changelog = _smf_generate_changelog(changelog, tickets, :html)
  markdown_changelog = _smf_generate_changelog(changelog, tickets, :markdown)
  slack_changelog = _smf_generate_changelog(changelog, tickets, :slack_markdown)
  all_ticket_tags = (ticket_tags + devops_ticket_tags).uniq.join(' ')

  smf_write_changelog(
    changelog: markdown_changelog,
    html_changelog: html_changelog,
    slack_changelog: slack_changelog,
    ticket_tags: all_ticket_tags,
    devops_tickets: tickets[:devops]  # Store devops tickets separately
  )
end

# Get commits with SHA between two refs
# @param from_ref [String] Starting ref (tag or commit)
# @param to_ref [String] Ending ref (usually 'HEAD')
# @return [Array<Hash>] Array of { sha: String, message: String }
def _smf_get_commits_with_sha(from_ref, to_ref)
  commits = []

  # Get commit SHAs and messages
  log_output = `git log #{from_ref}..#{to_ref} --pretty=format:"%H|||%s" 2>/dev/null`.strip

  return commits if log_output.empty?

  log_output.split("\n").each do |line|
    parts = line.split('|||', 2)
    next if parts.length < 2

    commits << {
      sha: parts[0].strip,
      message: parts[1].strip
    }
  end

  commits
end

############################## HELPER ##############################

private_lane :smf_super_atlassian_base_urls do
  [$JIRA_BASE_URL]
end

lane :smf_atlassian_base_urls do
  smf_super_atlassian_base_urls
end

def _smf_should_commit_be_ignored_in_changelog(commit_message, regexes_to_match)
  regexes_to_match.each do |regex|
    if commit_message.match(regex)
      UI.message("Ignoring commit: #{commit_message}")
      return true
    end
  end

  false
end

def _smf_changelog_temp_path
  "#{@fastlane_commons_dir_path}/#{$CHANGELOG_TEMP_FILE}"
end

def _smf_changelog_html_temp_path
  "#{@fastlane_commons_dir_path}/#{$CHANGELOG_TEMP_FILE_HTML}"
end

def _smf_changelog_slack_markdown_temp_path
  "#{@fastlane_commons_dir_path}/#{$CHANGELOG_TEMP_FILE_SLACK_MARKDOWN}"
end

def _smf_ticket_tags_temp_path
  "#{@fastlane_commons_dir_path}/#{$TICKET_TAGS_TEMP_FILE}"
end

def smf_remote_repo_name
  File.basename(`git config --get remote.origin.url`.strip).gsub('.git', '')
end

def smf_remote_repo_owner
  remote_url = `git config --get remote.origin.url`.strip
  result = remote_url.scan(/git@github.com:(.+)\//)

  return nil if result.first.nil?

  result.first.first
end
