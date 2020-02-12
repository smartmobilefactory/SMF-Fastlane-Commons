private_lane :smf_danger do |options|

  checkstyle_paths = []
  podspec_path = options[:podspec_path]
  bump_type = options[:bump_type]
  contexts_to_search = options[:contexts_to_search]
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

  _smf_find_paths_of('ktlint.xml').each { |path| checkstyle_paths.push(path) }
  _smf_find_paths_of('detekt.xml').each { |path| checkstyle_paths.push(path) }

  ENV['DANGER_ANDROID_LINT_PATHS'] = JSON.dump(lint_paths)
  ENV['DANGER_JUNIT_PATHS'] = JSON.dump(junit_result_paths)
  ENV['DANGER_CHECKSTYLE_PATHS'] = JSON.dump(checkstyle_paths)

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
    contexts_to_search,
    ticket_base_url
  )

  danger(
    github_api_token: ENV[$DANGER_GITHUB_TOKEN_KEY],
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

def _smf_create_jira_ticket_links(contexts_to_search, ticket_base_url)

  default_ticket_base_url = ticket_base_url.nil? ? 'https://smartmobilefactory.atlassian.net/' : ticket_base_url
  default_ticket_base_url += 'browse/'
  tickets = _smf_find_jira_tickets(contexts_to_search)

  ticket_urls = []

  tickets.each do | ticket |
    ticket_urls << "<a href='#{default_ticket_base_url}#{ticket}'>#{ticket}</a>"
  end

  ENV['DANGER_JIRA_TICKETS'] = "{ \"ticket_urls\" : #{ticket_urls} }"
end

def _smf_find_tickets_in(string, string_context)

  if string.nil?
    UI.error("Can't look for Jira Tickets in #{string_context}, content is nil!")
    return []
   end

  min_ticket_name_length = 2
  max_ticket_name_length = 14

  min_ticket_number_length = 1
  max_ticket_number_length = 8

  # This regex matches anything that starts with 2 or 14 captial letters, followed by a dash followed by 1 to 8 digits
  regex = /[A-Z]{#{min_ticket_name_length},#{max_ticket_name_length}}-[0-9]{#{min_ticket_number_length},#{max_ticket_number_length}}/
  tickets = string.scan(regex)

  if !tickets.empty? then UI.message("Found #{tickets} in #{string_context}") end

  return tickets.uniq
end

def _smf_find_jira_tickets(contexts_to_search)

  tickets = []

  contexts_to_search.each do |context, content|
    if context == 'commits'
      if !content.nil? then
        content.each do |message|
          tickets.concat(_smf_find_tickets_in(message, "commit message")).uniq
        end
      else
        UI.error("Can't look for Jira Tickets in commits, unable to download the commits of this PR!")
      end
    else
      tickets.concat(_smf_find_tickets_in(content, context)).uniq
    end
  end

  return tickets
end