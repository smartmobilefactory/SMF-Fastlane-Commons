# smf_increment_build_number

This lane increments the build number of the project if an app is built and returns the new tag.

### Example
Increment the build number.
```
smf_increment_build_number(
    current_build_number: <some number>,
    skip_build_nr_update_in_plists: false # optional, default to false, if true, the build number will not be updated in plists files
)
```

## Get the current build number
At the beginning, the current build number will be tried to get by fetching the last tag which matches the pattern *build/\*/\**. If there is a last tag the build number at the end of the tag will be chosen as the current build builder. Otherwise the current build number will be taken from the project itself. Nevertheless, it will be checked which one is greater. The greatest number will be increased and set as new build number.

### Build number contains '.'
If the build number contains one or multiple '.' only the first part of the number will be used.