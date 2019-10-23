### Build Variants for Pod PR Check
This lane returns an array which contains all build variants which need to be build for a PR check.

If the is a build variant specified in the Config.json which contains *alpha* and array containing this build variant will be returned. In case there are multiple alpha build variants, only the first one will be returned in an array.

Otherwise an array containing all build variants which contain *example* will be returned.

Example:

```
smf_build_variants_for_pod_pr_check()
```