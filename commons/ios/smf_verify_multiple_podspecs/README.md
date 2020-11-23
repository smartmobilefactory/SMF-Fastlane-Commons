### Lint all Podspecs

This lane assures that if the project contains multiple podspec-files. That all of them work/build correctly. This is important to reduce the risk of one of the pod push commands failing, which would lead to an inconsistency across the podspecs.

Example:

```
smf_lint_podspecs(
    podspecs: <array with all podspec paths of this project>    # Important: this array should also include the "main" podspec and not only the additional ones
    required_xcode_version: <xcode version from config json>
)
```