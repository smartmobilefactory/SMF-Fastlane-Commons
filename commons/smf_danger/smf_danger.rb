private_lane :smf_danger do |options|

  checkstyle_paths = []
  podspec_path = options[:podspec_path]
  bump_type = options[:bump_type]
  pr_number = options[:pr_number]
  branch_name = options[:branch_name]
  ticket_base_url = options[:ticket_base_url]

  if File.exist?(smf_swift_lint_output_path)
    checkstyle_paths.push(smf_swift_lint_output_path)
  elsif [:ios, :ios_framework, :macos].include?(@platform)
    UI.important("There is not SwiftLint output file at #{smf_swift_lint_output_path}. Is SwiftLint enabled?")
  end

  if @platform == :android
    UI.user_error!("android-commons not present! Can't start danger") unless File.exist?('../android-commons')
  end

  lint_paths = _smf_find_paths_of('lint-result.xml')
  junit_result_paths = _smf_find_paths_of_files_in_directory('build/test-results', 'xml')

  _smf_find_paths_of('klint.xml').each { |path| checkstyle_paths.push(path) }
  _smf_find_paths_of('detekt.xml').each { |path| checkstyle_paths.push(path) }

  ENV["DANGER_ANDROID_LINT_PATHS"] = JSON.dump(lint_paths)
  ENV["DANGER_JUNIT_PATHS"] = JSON.dump(junit_result_paths)
  ENV["DANGER_CHECKSTYLE_PATHS"] = JSON.dump(checkstyle_paths)

  if (@platform == :ios_framework && !bump_type.nil?)
    if bump_type == ''
      ENV['MULTIPLE_BUMP_TYPES_ERROR'] = 'true'
    else
      version_number = smf_increment_version_number_dry_run(
          podspec_path: podspec_path,
          bump_type: bump_type
      )

      ENV['POD_VERSION'] = version_number
    end
  end

  _smf_create_jira_ticket_links(
    pr_number,
    branch_name,
    ticket_base_url
  )

  danger(
    github_api_token: ENV["DANGER_GITHUB_API_TOKEN"],
    dangerfile: "#{File.expand_path(File.dirname(__FILE__))}/Dangerfile",
    verbose: true
  )
end

def _smf_find_paths_of(filename)
  paths = []
  Dir["#{smf_workspace_dir}/**/#{filename}"].each do |file|
    paths.append(File.expand_path(file))
  end
  paths
end

def _smf_find_paths_of_files_in_directory(directory, file_type = '')
  paths = []
  file_type = ".#{file_type}" if file_type != ''
  Dir["#{smf_workspace_dir}/**/#{directory}/*#{file_type}"].each do |file|
    paths.append(File.expand_path(file))
  end
  paths
end



def _smf_create_jira_ticket_links(pr_number, branch_name, ticket_base_url)

  git_url = smf_get_repo_url

  UI.message("pr_number is: #{pr_number}")
  UI.message("branch_name is: #{branch_name}")
  UI.message("git_url is: #{git_url}")

  default_ticket_base_url = ticket_base_url.nil? ? 'https://smartmobilefactory.atlassian.net/browse/' : ticket_base_url
  tickets = _smf_find_jira_tickets(pr_number, git_url, branch_name)

  ticket_urls = []

  tickets.each do | ticket |
    ticket_urls << "<a href='#{default_ticket_base_url}#{ticket}'>#{ticket}</a>"
  end

  ENV["DANGER_JIRA_TICKETS"] = "{ \"ticket_urls\" : #{ticket_urls} }"
end

def _smf_find_tickets_in(string)
  regex = /(?<=\s|[^a-zA-Z])[A-Z]{2,14}-[0-9]{1,8}/
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
  if !tickets_from_pr_title.empty? then UI.message("Found #{tickets_from_pr_title} in pull request title") end
  tickets.concat(tickets_from_pr_title).uniq

  pr_body = smf_github_get_pr_body(pr_number, git_url)
  tickets_from_pr_body = _smf_find_tickets_in(pr_body)
  if !tickets_from_pr_body.empty? then UI.message("Found #{tickets_from_pr_body} in pull request body") end
  tickets.concat(tickets_from_pr_body).uniq

  tickets_from_branch_name = _smf_find_tickets_in(branch_name)
  if !tickets_from_branch_name.empty? then UI.message("Found #{tickets_from_branch_name} in branch_name") end
  tickets.concat(tickets_from_branch_name).uniq

  commit_messages = smf_github_get_commit_messages_for_pr(pr_number, git_url)
  if !commit_messages.nil? then

    commit_messages.each do | message |
      tickets_from_message = _smf_find_tickets_in(message)
      if !tickets_from_message.empty? then UI.message("Found #{tickets_from_message} in commit message") end
      tickets.concat(tickets_from_message).uniq
    end
  end

  return tickets
end