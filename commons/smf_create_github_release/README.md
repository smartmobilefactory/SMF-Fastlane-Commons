# smf_create_github_release

This lane creates a new GitHub release, which has the current tag. 

### Example
Create a GitHub release.
```
smf_create_github_release(
    release_name: 'ALPHA 77'
    tag: 'build/alpha/77',
    paths: [] #Optional
)
``` 