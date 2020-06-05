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
    merge_commit_filtering: 'exclude_merges',
    pretty: '- (%an) %s'
  )

  changelog_messages = '' if changelog_messages.nil?

  cleaned_changelog_messages = []
  changelog_messages.split(/\n+/).each do |commit_message|
    if _smf_should_commit_be_ignored_in_changelog(commit_message, [/.*SMFHUDSONCHECKOUT.*/])
      next
    end

    # Remove the author and use uppercase at line starts for non internal builds
    commit_message = commit_message.sub(/^- \([^\)]*\) /, '- ')
    letters = commit_message.split('')
    letters[2] = letters[2].upcase if letters.length >= 2
    commit_message = letters.join('')
    cleaned_changelog_messages.push(commit_message)

  end

  # Limit the size of changelog as it's crashes if it's too long
  tickets = _smf_generate_tickets(cleaned_changelog_messages.uniq)

  changelog = cleaned_changelog_messages.uniq.join("\n")
  changelog = "#{changelog[0..20_000]}#{'\\n...'}" if changelog.length > 20_000
  changelog = changelog.split("\n")

  html_changelog = _smf_generate_changelog(changelog, tickets, :html)
  markdown_changelog = _smf_generate_changelog(changelog, tickets, :markdown)

  smf_write_changelog(
    changelog: markdown_changelog,
    html_changelog: html_changelog
  )
end

############################## HELPER ##############################

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

def _smf_remote_repo_name
  File.basename(`git config --get remote.origin.url`.strip).gsub('.git', '')
end

def _smf_generate_tickets(changelog)

  tickets = {
    normal: [],
    linked: [],
    unknown: []
  }

  return tickets if changelog.nil?

  ticket_tags = []

  # find all ticket tags
  changelog.each do |commit_message|
    # find ticket tags in the commit message itself
    ticket_tags += smf_find_ticket_tags_in(commit_message)
    # if the commit message was a merge, check the corresponding PR
    ticket_tags += _smf_find_ticket_tags_in_related_pr(commit_message)
  end

  ticket_tags.uniq.each do |ticket_tag|
    title = _smf_fetch_ticket_summary_for(ticket_tag)

    if title.nil?
      unknown_ticket = { tag: ticket_tag }
      tickets[:unknown].push(unknown_ticket)
      next
    end

    link = File.join($JIRA_BASE_URL, 'browse', ticket_tag)

    # get linked
    linked_tickets = _smf_fetch_linked_tickets_for(ticket_tag)

    new_ticket = {
      tag: ticket_tag,
      link: link,
      title: title,
      linked_tickets: linked_tickets
    }

    tickets[:normal].push(new_ticket)
    tickets[:linked].concat(linked_tickets)
  end

  tickets[:normal].uniq!
  tickets[:linked].uniq!
  tickets[:unknown].uniq!

  tickets
end

def _smf_find_ticket_tags_in_related_pr(commit_message)

  matches = commit_message.scan(/.*\(#([0-9]*)\)\z/)
  return [] if matches.empty?

  pull_number = matches[0][0]

  pr_data = _smf_fetch_pull_request_data(pull_number)
  ticket_tags = smf_find_jira_ticket_tags_in_pr(pr_data)

  ticket_tags
end

############################## API REQUESTS ##############################

# Helper function for basci https requests
def _smf_https_get_request(url, auth_type, credentials)
  uri = URI(url)

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Get.new(uri)
  if auth_type == :basic
    credentials = credentials.split(':')
    req.basic_auth(credentials[0], credentials[1])
  elsif auth_type == :token
    req['Authorization'] = "token #{credentials}"
  end

  res = https.request(req)

  return nil if res.code != '200'

  JSON.parse(res.body, {symbolize_names: true})
end

# Get the ticket title from jira
def _smf_fetch_ticket_summary_for(ticket_tag)
  res = _smf_https_get_request(
    File.join($JIRA_BASE_URL, 'rest/api/latest/issue', ticket_tag),
    :basic,
    ENV[$JIRA_DEV_ACCESS_CREDENTIALS]
  )

  return nil if res.nil?

  res.dig(:fields, :summary)
end

def _smf_fetch_linked_tickets_for(ticket_tag)
  res = _smf_https_get_request(
    File.join($JIRA_BASE_URL, 'rest/api/latest/issue', ticket_tag, 'remotelink'),
    :basic,
    ENV[$JIRA_DEV_ACCESS_CREDENTIALS]
  )

  related_tickets = []

  return related_tickets if res.nil?

  res.each do |ticket_data|
    ticket = {}

    ticket[:link] = ticket_data.dig(:object, :url)
    next if ticket[:link].nil?

    ticket[:tag] = File.basename(ticket[:link])
    ticket[:title] = ticket_data.dig(:object, :title)
    related_tickets.push(ticket)
  end

  related_tickets.uniq
end

# get PR body, title and commits for a certain pull request
def _smf_fetch_pull_request_data(pr_number)
  repo_name = _smf_remote_repo_name
  base_url = "https://api.github.com/repos/smartmobilefactory/#{repo_name}/pulls/#{pr_number}"

  pull_request = _smf_https_get_request(
    base_url,
    :token,
    ENV[$SMF_GITHUB_TOKEN_ENV_KEY]
  )

  begin
    title = pull_request.dig(:title)
    body = pull_request.dig(:body)
  rescue
    title = nil
    body = nil
  end

  commits = _smf_https_get_request(
    base_url + '/commits',
    :token,
    ENV[$SMF_GITHUB_TOKEN_ENV_KEY]
  )

  begin
    commits = commits.map {|commit| commit.dig(:commit, :message)}.compact.uniq
  rescue
    commits = nil
  end

  pr_data = {
    body: body,
    title: title,
    commits: commits
  }

  pr_data
end

