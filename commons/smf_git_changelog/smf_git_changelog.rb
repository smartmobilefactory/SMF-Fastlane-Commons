#############################
### smf_git_changelog ###
#############################

desc 'Collect git commit messages into a changelog and store as environment variable.'
private_lane :smf_git_changelog do |options|

  build_variant = options[:build_variant].downcase if !options[:build_variant].nil?
  is_library = !options[:is_library].nil? ? options[:is_library] : false
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

  changelog_messages = changelog_from_git_commits(
    between: [last_tag, 'HEAD'],
    merge_commit_filtering: 'include_merges',
    pretty: '- (%an) %s'
  )

  changelog_messages = '' if changelog_messages.nil?

  cleaned_changelog_messages = []
  ignored_commits = [/Release Pod.*/, /Increment build number.*/, /Updating i18n/]
  changelog_messages.split(/\n+/).each do |commit_message|
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

  # Extract related Jira issues info
  tickets_tags = smf_get_ticket_tags_from_changelog(cleaned_changelog_messages.uniq)
  UI.message("Jira tickets found: #{ticket_tags}")
  tickets = smf_generate_tickets_from_tags(ticket_tags)

  # Limit the size of changelog as it's crashes if it's too long
  changelog = cleaned_changelog_messages.uniq.join("\n")
  changelog = "#{changelog[0..20_000]}#{'\\n...'}" if changelog.length > 20_000
  changelog = changelog.split("\n")

  # Convert changelog to different output formats
  html_changelog = _smf_generate_changelog(changelog, tickets, :html)
  markdown_changelog = _smf_generate_changelog(changelog, tickets, :markdown)
  slack_changelog = _smf_generate_changelog(changelog, tickets, :slack_markdown)
  ticket_tags = ticket_tags.join(' ') # convert array to string list

  smf_write_changelog(
    changelog: markdown_changelog,
    html_changelog: html_changelog,
    slack_changelog: slack_changelog,
    ticket_tags: ticket_tags
  )
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
  "#{@fastlane_commons_dir_path}/#{$CHANGELOG_TEMP_FILE_SLACK_MARKDOWN}"
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
