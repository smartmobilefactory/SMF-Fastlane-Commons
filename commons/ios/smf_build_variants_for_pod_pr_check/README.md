### Build Variants for Pod PR Check
This lane returns an array which contains all build variants which need to be build for a PR check.

If a specific build_variant has been specified in the pipeline then only that one is returned as an array.

If no parameters are given then this lane will search for a build variants in the Config.json containing either (and in this priority order) *alpha* then *unittests* then *example*.

In case there are multiple *alpha* build variants, only the first one will be returned in an array.

Example without parameters to check build_variants from the Config.json:

```
smf_build_variants_for_pod_pr_check()
```

Example with parameters to use a specific build_variant:

```
smf_build_variants_for_pod_pr_check(options)
```
