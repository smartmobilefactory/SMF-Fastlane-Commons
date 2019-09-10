# smf_push_to_git_remote

This lane pushes to git.

### Example
Push to git.
```
smf_push_to_git_remote(
    remote: 'origin', #Optional, 'origin' by default
    local_branch: 'test', #Optional, default is set to current branch
    remote_branch: 'test2' #Optional, default is set to local_branch 
    force: false, #Optional, false by default
    tags: false, #Optional, true by default
)
``` 