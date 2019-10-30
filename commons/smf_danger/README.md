# smf_danger

This lane collects all paths from linter tasks and runs *danger* from Fastlane.

### Example
```
smf_danger(
    jira_keys: [],                              # Optional, by default []
    modules: [],                                # Optional, see *smf_danger_module_config* for further information
    podspec_path: <path to podspec file>        # only needed for ios frameworks
    bump_type: <either internal or breaking>    # only needed for ios frameworks
)
```

#### Note

The `podspec_path` and `bump_type` are used to calculate the upcoming pod version and add it to dangers pull request report.
