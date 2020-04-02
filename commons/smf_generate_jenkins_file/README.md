## Generates Jenkins file
This lane generates the Jenkins file for this project. But it can also be used to generate custom jenkinsfiles for tools for example.
Therefore some optional parameters are available to set the template and output path, and also to remove multibuild variants (e.g. "Alpha", "Beta", ...) if needed.

Example:

```
smf_generate_jenkins_file(
  custom_jenkinsfile_template: <path_to_template>                                   # optional
  custom_jenkinsfile_path: <path_to_store_new_jenkinsfile>                          # optional 
  remove_multibuild_variants: <boolean: if true "Alpha", "Beta", etc. are removed>  # optional, defaults to false
)
```