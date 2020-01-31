require 'json'

def smf_get_repo_url
  url = `git remote get-url origin`.gsub("\n", '')

  return url
end

def smf_github_get_commit_messages_for_pr(pr_number, git_repo_url)
  request_url = _smf_github_create_api_url(git_repo_url, pr_number)+ "/commits"
  UI.message("Request URL for commits: #{request_url}")
  response = `curl -X GET -s -H "Authorization: token #{ENV[$SMF_GITHUB_TOKEN_ENV_KEY]}" #{request_url}`
  response_as_json = JSON.parse(response)

  if !response_as_json.is_a?(Array) then
    UI.error("Error getting commit messages for pull request number #{pr_number} in for repository: #{git_repo_url}")
    return nil
  end

  commit_messages = []

  response_as_json.each do | commit |
    commit_messages << commit['commit']['message']
  end

  return commit_messages
end

def smf_github_get_pull_request(pr_number, git_repo_url)
  request_url = _smf_github_create_api_url(git_repo_url, pr_number)
  UI.message("Request URL for pull request: #{request_url}")
  response = `curl -X GET -s -H "Authorization: token #{ENV[$SMF_GITHUB_TOKEN_ENV_KEY]}" #{request_url}`
  UI.message("Response: \n#{response}")
  response_as_json = JSON.parse(response)

  if response_as_json['message'] == 'Not Found'
    UI.error("Error getting commit messages for pull request number #{pr_number} in for repository: #{git_repo_url}")
    return nil
  end

  return response_as_json
end

def smf_github_get_pr_body(pr_number, git_url)
  pull_request = smf_github_get_pull_request(pr_number, git_url)
  UI.message("Found pr body: #{pull_request['body']}")
  return pull_request.nil? ? nil : pull_request['body']
end

def smf_github_get_pr_title(pr_number, git_url)
  pull_request = smf_github_get_pull_request(pr_number, git_url)
  UI.message("Found pr title: #{pull_request['title']}")
  return pull_request.nil? ? nil : pull_request['title']
end

def _smf_github_create_api_url(git_repo_url, pr_number)
  request_url = git_repo_url.gsub('.git', "/pulls/#{pr_number}").gsub('git@github.com:', 'https://api.github.com/repos/').gsub("https://github.com", "https://api.github.com/repos")

  return request_url
end