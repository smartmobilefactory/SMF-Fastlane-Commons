private_lane :smf_push_to_git_remote do |options|

  remote = !options[:remote].nil? ? options[:remote] : 'origin'
  local_branch = options[:local_branch]
  remote_branch = !options[:remote_branch].nil? ? options[:remote_branch] : local_branch
  force = !options[:force].nil? ? options[:force] : false
  tags = !options[:tags].nil? ? options[:tags] : true

  push_to_git_remote(
      remote: remote,
      local_branch: local_branch,
      remote_branch: remote_branch,
      force: force,
      tags: tags
  )
end

