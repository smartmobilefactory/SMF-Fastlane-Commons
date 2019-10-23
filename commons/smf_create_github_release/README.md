# smf_create_github_release

This lane creates a new GitHub release, which has the current tag. 

### Example
Create a GitHub release.
```
smf_create_github_release(
    build_number: 77,                       # The projects current build number
    tag: 'build/alpha/77',
    paths: [],                              # Optional: Paths to files to attach to the release
    branch: "master",                       # Specifies the commitish value that determines where the Git tag is created from. Can be any branch or commit SHA
    build_variant: "alpha",                 # The current build variant
    changelog: <changelog up to this tag>   # the changelog to be added to the new release
    podspec_path: <path to podspec file>    # Needed only for pod releases
)
``` 