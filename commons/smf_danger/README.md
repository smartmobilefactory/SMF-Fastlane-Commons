# smf_danger

This lane collects all paths from linter tasks and runs *danger* from Fastlane.

### Example
```
smf_danger(
    modules: [],                                    # Optional, see *smf_danger_module_config* for further information
    podspec_path: <path to podspec file>            # only needed for ios frameworks
    bump_type: <either internal or breaking>        # only needed for ios frameworks
    pr_number: <pull request number>,               # needed to automativally detect jira tickets
    branch_name: <the name of the current branch>,  # needed to automativally detect jira tickets
    ticket_base_url: <base url for jira tickets>    # Optional, default is https://smartmobilefactory.atlassian.net/browse/          
)
```

#### Note

The `podspec_path` and `bump_type` are used to calculate the upcoming pod version and add it to dangers pull request report.

##### Jira Tickets Auto Detection

The `pr_number` and `branch_name` (and `ticket_base_url`) are used to automatically detect the Jira Issue associated with
the Pull Request and add them to the danger log.
If you want to use a custom base url for the jira issues, add a property with the key `jira_ticket_base_url` to the build 
variants config.json entry.
