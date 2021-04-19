# Get the ticket title from jira
def _smf_fetch_ticket_data_for(ticket_tag)
  res = nil
  base_url = nil

  smf_atlassian_base_urls.each do |url|
    res = _smf_https_get_request(
      File.join(url, 'rest/api/latest/issue', ticket_tag),
      :basic,
      ENV[$JIRA_DEV_ACCESS_CREDENTIALS]
    )

    unless res.nil?
      base_url = url
      break
    end
  end

  result = {
    base_url: base_url
  }

  result[:title] = res.dig(:fields, :summary) unless res.nil?
  result[:linked_tickets] = _smf_extract_linked_issues(res, base_url)

  result
end

def _smf_fetch_remote_tickets_for(ticket_tag, base_url)
  res = _smf_https_get_request(
    File.join(base_url, 'rest/api/latest/issue', ticket_tag, 'remotelink'),
    :basic,
    ENV[$JIRA_DEV_ACCESS_CREDENTIALS]
  )

  UI.message("Result linked: #{res}")

  related_tickets = []

  return related_tickets if res.nil?

  res.each do |ticket_data|
    ticket = {}

    ticket[:link] = ticket_data.dig(:object, :url)
    next if ticket[:link].nil?

    # This is to check whether the link is actually a ticket
    regex = Regexp.new('browse\/(' + smf_jira_ticket_regex_string + ')')
    ticket_tags = ticket[:link].scan(regex)
    next if ticket_tag.empty?

    begin
      ticket[:tag] = ticket_tags.first.first
    rescue
      next
    end

    ticket[:title] = ticket_data.dig(:object, :title)
    related_tickets.push(ticket)
  end

  related_tickets.uniq
end

def _try_dig(map, key)
  value = nil
  begin
    value = map.dig(key)
  rescue
    value = nil
  end

  value
end

# get PR body, title and commits for a certain pull request
def _smf_fetch_pull_request_data(pr_number)
  repo_name = smf_remote_repo_name

  repo_owner = smf_remote_repo_owner
  repo_owner = 'smartmobilefactory' if repo_owner.nil?

  base_url = "https://api.github.com/repos/#{repo_owner}/#{repo_name}/pulls/#{pr_number}"

  pull_request = _smf_https_get_request(
    base_url,
    :token,
    ENV[$SMF_GITHUB_TOKEN_ENV_KEY]
  )

  title = _try_dig(pull_request, :title)
  body = _try_dig(pull_request, :body)
  pr_link = _try_dig(pull_request, :html_url)
  branch = _try_dig(pull_request, :head)

  unless branch.nil?
    branch = _try_dig(branch, :ref)
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
    commits: commits,
    pr_link: pr_link,
    branch: branch
  }

  pr_data
end

def _smf_extract_linked_issues(ticket_data, base_url)
  linked_issues = []

  return nil if ticket_data.nil? || base_url.nil?

  issues = ticket_data.dig(:fields, :issuelinks)

  return nil if issues.nil?

  issues.each do |issue_data|
    linked_issues.push(_smf_extract_issue(issue_data, :outwardIssue, base_url))
    linked_issues.push(_smf_extract_issue(issue_data, :inwardIssue, base_url))
  end

  linked_issues.compact
end

def _smf_extract_issue(issue_data, type, base_url)
  ticket = {}
  issue = issue_data[type]
  return nil if issue.nil?

  ticket[:title] = issue.dig(:fields, :summary)
  ticket[:tag] = issue[:key]
  ticket[:link] = File.join(base_url, 'browse', ticket[:tag])

  ticket
end
