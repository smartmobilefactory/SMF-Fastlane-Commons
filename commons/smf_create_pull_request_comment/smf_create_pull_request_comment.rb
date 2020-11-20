private_lane :smf_create_pull_request_comment do |options|

  comment = options[:comment]

  # Check if the number of this pull request is available
  if ENV["CHANGE_ID"].nil?
    UI.important("Error adding comment on pull request! The pull request number is not available, make sure you are in a PR check!")
    next
  end

  git_remote_origin_url = sh 'git config --get remote.origin.url'
  matcher = git_remote_origin_url.match(/github\.com(:|\/)(.+)\/(.+)\.git/)

  if !matcher.nil? && !matcher.captures.nil? && matcher.captures.count == 3 && !ENV["CHANGE_ID"].nil?
      repo_owner = matcher.captures[1]
      repo_name = matcher.captures[2]

      UI.message("Commenting on the pull request.")

      comment = comment.gsub('""', '\"')

      sh("curl -H \"Authorization: token #{ENV[$SMF_GITHUB_TOKEN_ENV_KEY]}\" -d '{\"body\": \"#{comment}\"}' -X POST https://api.github.com/repos/#{repo_owner}/#{repo_name}/issues/#{ENV["CHANGE_ID"]}/comments -sS -o /dev/null")
  else
    UI.important("Error adding comment on pull request! Unable to extract repository name and repository owner from remote origin url!")
  end
end