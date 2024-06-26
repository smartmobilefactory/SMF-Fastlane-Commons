## Update Generated Files
This lane generates the Jenkinsfile and additional files (optional) and pushes new changes if it was not up to date.
If you want to update custom jenkins files, you can pass a list of dictionaries to this lane.
Each dict should contain:
    - The template path
    - The path to the generated file
    - boolean whether or not to include multi-build variant in the jenkins file build variants array.

Example:

```
smf_update_generated_files(
    ios_build_nodes: ['iosbuild', 'mobileci7', ...],   # optional, but needed for all none android jobs, possible build nodes for ios projects
    files_to_update: [ {                               \
            :template => <path to template>,            |
            :file => <path to file>,                    |
            :remove_multibuilds => <true or false>      |--- optional parameter (used in sparkle package creator, see tools)
        },                                              |
        ...                                             |
    ]                                                   /
)
```