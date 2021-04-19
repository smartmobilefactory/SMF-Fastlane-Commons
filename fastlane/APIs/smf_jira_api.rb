########################## TICKETS API ##############################

# Get the ticket title from jira
def smf_jira_fetch_ticket_data_for(ticket_tag)
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

def smf_jira_fetch_related_tickets_for(ticket_tag, base_url)
  res = _smf_https_get_request(
    File.join(base_url, 'rest/api/latest/issue', ticket_tag, 'remotelink'),
    :basic,
    ENV[$JIRA_DEV_ACCESS_CREDENTIALS]
  )

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

########################## COMMENTS API ##############################
