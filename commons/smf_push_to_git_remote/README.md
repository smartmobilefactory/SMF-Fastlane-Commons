# smf_push_to_git_remote

This lane pushes to git.

### Example
Push to git.
```
smf_push_to_git_remote(
    remote: 'origin', #Optional, 'origin' by default
    branch: master, 
    force: false, #Optional, false by default
    tags: false, #Optional, true by default
)
``` 