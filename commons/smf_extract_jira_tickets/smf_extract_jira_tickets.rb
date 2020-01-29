
private_lane :smf_create_jira_ticket_links do |options|
  pr_number = options[:pr_number]
  git_url = options[:git_url]
  branch_name = options[:branch_name]
  ticket_base_url = options[:ticket_base_url]

  UI.message("DEBUGGING: pr_number is: #{pr_number}")
  UI.message("DEBUGGING: git_url is: #{git_url}")
  UI.message("DEBUGGING: branch_name is: #{branch_name}")
  UI.message("DEBUGGING: ticket_base_url is: #{ticket_base_url}")

  default_ticket_base_url = ticket_base_url.nil? ? 'https://smartmobilefactory.atlassian.net/browse/' : ticket_base_url
  tickets = _smf_find_jira_tickets(pr_number, git_url, branch_name)

  ticket_urls = []

  tickets.each do | ticket |
    ticket_urls << "<a href='#{default_ticket_base_url}#{ticket}'>#{ticket}</a>"
  end

  ENV["DANGER_JIRA_TICKETS"] = "{ \"ticket_urls\" : #{ticket_urls} }"
end

def _smf_find_tickets_in(string)
  regex = /(?<=\s|[^a-zA-Z])[A-Z]{2,10}-[0-9]{1,8}/
  matches = string.match(regex)

  tickets = []

  return tickets if matches.nil?

  matches.to_a.each do | match |
    tickets << match
  end

  return tickets.uniq
end

def _smf_find_jira_tickets(pr_number, git_url, branch_name)

  tickets = []

  pr_title = smf_github_get_pr_title(pr_number, git_url)
  tickets_from_pr_title = _smf_find_tickets_in(pr_title)
  if !tickets_from_pr_title.empty? then print("Found #{tickets_from_pr_title} in pull request title\n") end
  tickets.concat(tickets_from_pr_title).uniq

  pr_body = smf_github_get_pr_body(pr_number, git_url)
  tickets_from_pr_body = _smf_find_tickets_in(pr_body)
  if !tickets_from_pr_body.empty? then print("Found #{tickets_from_pr_body} in pull request body\n") end
  tickets.concat(tickets_from_pr_body).uniq

  tickets_from_branch_name = _smf_find_tickets_in(branch_name)
  if !tickets_from_branch_name.empty? then print("Found #{tickets_from_branch_name} in branch_name\n") end
  tickets.concat(tickets_from_branch_name).uniq

  commit_messages = smf_github_get_commit_messages_for_pr(pr_number, git_url)
  if !commit_messages.nil? then

    commit_messages.each do | message |
      tickets_from_message = _smf_find_tickets_in(message)
      if !tickets_from_message.empty? then print("Found #{tickets_from_message} in commit message\n") end
      tickets.concat(tickets_from_message).uniq
    end
  end

  return tickets
end