# smf_create_github_release

This lane creates a new GitHub release, which has the current tag. 

### Example
Create a GitHub release.
```
smf_create_github_release(
    release_name: 'ALPHA 77'
    tag: 'build/alpha/77',
    paths: [],                              # Optional: Paths to files to attach to the release
    branch: "master",                       # Specifies the commitish value that determines where the Git tag is created from. Can be any branch or commit SHA
    build_variant: "alpha",                 # The current build variant
    changelog: <changelog up to this tag>   # the changelog to be added to the new release
)
``` 