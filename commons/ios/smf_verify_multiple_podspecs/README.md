### Lint all Podspecs

This lane assures that if the project contains multiple podspec-files. That all of them work/build correctly. This is important to reduce the risk of one of the pod push commands failing, which would lead to an inconsistency across the podspecs.

Example:

```
smf_lint_podspecs(
    main_podspec:  <path to the main podspec>
    additional_podspecs:  <array with all additional podspec paths of this project>  # Important: this array should only include the additional_podspecs
    required_xcode_version: <xcode version from config json>
)
```