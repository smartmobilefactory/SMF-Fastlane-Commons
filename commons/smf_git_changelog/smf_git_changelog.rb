#############################
### smf_git_changelog ###
#############################

desc 'Collect git commit messages and author mail adresses into a changelog and store them as environmental varibles.'
private_lane :smf_git_changelog do |options|

  build_variant = options[:build_variant]
  UI.important('Collecting commits back to the last tag')

  # Constants
  NO_GIT_TAG_FAILURE = 'NO_GIT_TAG_FAILURE'

  # Pull all the tags so the change log collector finds the latest tag
  UI.message('Fetching all tags...')
  sh('git fetch --tags --quiet')

  last_tag = sh("git describe --tags --match \".*#{build_variant}.*\" --abbrev=0 HEAD --first-parent || echo #{NO_GIT_TAG_FAILURE}").to_s

  # Use the initial commit if there is no matching tag yet
  if last_tag.include? NO_GIT_TAG_FAILURE
    last_tag = sh('git rev-list --max-parents=0 HEAD').to_s
  end

  last_tag = last_tag.strip

  UI.important("Using tag: #{last_tag} to compare with HEAD")

  changelog_messages = changelog_from_git_commits(
      between: [last_tag, 'HEAD'],
      merge_commit_filtering: 'exclude_merges',
      pretty: '- (%an) %s'
  )

  changelog_messages = '' if changelog_messages.nil?

  cleaned_changelog_messages = []
  changelog_messages.split(/\n+/).each do |commit_message|
    if smf_should_commit_be_ignored_in_changelog(commit_message, [/.*SMFHUDSONCHECKOUT.*/])
      next
    end

    # Remove the author and use uppercase at line starts for non internal builds
    commit_message = commit_message.sub(/^- \([^\)]*\) /, '')
    commit_message.capitalize
    cleaned_changelog_messages.push(commit_message)
  end

  # Limit the size of changelog as it's crashes if it's too long
  changelog = cleaned_changelog_messages.uniq.join("\n")
  changelog = "#{changelog[0..20_000]}#{'\\n...'}" if changelog.length > 20_000
  UI.important("test 1")
  changelog_html = "<ul>#{cleaned_changelog_messages.uniq.map { |x| "<li>#{x}</li>" }.join("")}</ul>"
  UI.important("test 2")
  ENV[$SMF_CHANGELOG_ENV_HTML_KEY] = changelog_html.to_s
  UI.important("test 3")
  UI.important("SMF_CHANGELOG_ENV_HTML_KEY:\n #{ENV[$SMF_CHANGELOG_ENV_HTML_KEY]}")
  UI.important("test 4")
  ENV[$SMF_CHANGELOG_ENV_KEY] = changelog
  UI.important("test 5")
end

##############
### Helper ###
##############

def smf_should_commit_be_ignored_in_changelog(commit_message, regexes_to_match)
  regexes_to_match.each do |regex|
    if commit_message.match(regex)
      UI.message("Ignoring commit: #{commit_message}")
      return true
    end
  end

  false
end
