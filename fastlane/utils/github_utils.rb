require 'json'

def smf_github_get_commit_messages_for_pr(number, git_url)
  request_url = git_url.gsub('.git', "/pulls/#{number}/commits").gsub('git@github.com:', 'https://api.github.com/repos/')
  response = `curl -X GET -s -H "Authorization: token #{ENV[$SMF_GITHUB_TOKEN_ENV_KEY]}" #{request_url}`
  response_as_json = JSON.parse(response)

  if !response_as_json.is_a?(Array) then
    UI.warning("Error getting commit messages for pull request number #{number} in for repository: #{git_url}")
    return nil
  end

  commit_messages = []

  response_as_json.each do | commit |
    commit_messages << commit['commit']['message']
  end

  return commit_messages
end

def smf_github_get_pull_request(number, git_url)
  request_url = git_url.gsub('.git', "/pulls/#{number}").gsub('git@github.com:', 'https://api.github.com/repos/')
  response = `curl -X GET -s -H "Authorization: token #{ENV[$SMF_GITHUB_TOKEN_ENV_KEY]}" #{request_url}`
  response_as_json = JSON.parse(response)

  if response_as_json['message'] == 'Not Found'
    UI.warning("Error getting commit messages for pull request number #{number} in for repository: #{git_url}")
    return nil
  end

  return response_as_json
end

def smf_github_get_pr_body(number, git_url)
  pull_request = smf_github_get_pull_request(number, git_url)
  return pull_request.nil? ? nil : pull_request['body']
end

def smf_github_get_pr_title(number, git_url)
  pull_request = smf_github_get_pull_request(number, git_url)
  return pull_request.nil? ? nil : pull_request['title']
end