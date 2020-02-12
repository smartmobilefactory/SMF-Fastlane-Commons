# smf_danger

This lane collects all paths from linter tasks and runs *danger* from Fastlane.

### Example
```
smf_danger(
    modules: [],                                            # Optional, see *smf_danger_module_config* for further information
    podspec_path: <path to podspec file>                    # only needed for ios frameworks
    bump_type: <either internal or breaking>                # only needed for ios frameworks
    ticket_base_url: <base url for jira tickets>            # Optional, default is https://smartmobilefactory.atlassian.net/        
)
```

##### Note

The `podspec_path` and `bump_type` are used to calculate the upcoming pod version and add it to dangers pull request report.

#### Jira Tickets Auto Detection

The pr title, pr body, branch name and commits are searched to automatically detect the Jira Issue associated with the Pull Request and add them to the danger log. If you want to use a custom base url for the jira issues, you can override the `smf_pipeline_danger_lane` (depends on the platform, see NOTEs below) and add the base url to the options map. Here  is an example:
```
override_lane :smf_pipeline_danger do |options|
  options[:jira_ticket_base_url] = '<your default base url>'

  smf_super_pipeline_danger(options)
end
```
For example if the base url is `https://acme.atlassian.net/` a `browse/` is added and then this is put in front of the ticket tag. Assuming the ticket tag `TICKET-123` is found, this produces `https://acme.atlassian.net/browse/TICKET-123`.

**NOTE**: For a framework the lanes are called `:smf_pod_danger` and `:smf_super_pod_danger`. And for flutter projects the lanes are called `smf_shared_pipeline_danger` and `smf_super_shared_pipeline_danger`.
