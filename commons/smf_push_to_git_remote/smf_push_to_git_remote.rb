private_lane :smf_push_to_git_remote do |options|

  remote = !options[:remote].nil? ? options[:remote] : 'origin'
  branch = options[:branch]
  force = !options[:force].nil? ? options[:force] : false
  tags = !options[:tags].nil? ? options[:tags] : true
  UI.message('push to git remote')

  push_to_git_remote(
      remote: remote,
      local_branch: branch,
      remote_branch: branch,
      force: force,
      tags: tags
  )
end

