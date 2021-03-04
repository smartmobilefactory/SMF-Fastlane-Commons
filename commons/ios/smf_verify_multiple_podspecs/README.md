### Lint all Podspecs

This lane assures that the podspecs are valid and able to build on all supported platform. This will lint all podspecs present in the project root folder. This is important to reduce the risk of one of the pod push commands failing, which would lead to an inconsistency across the podspecs.

Example:

```
smf_lint_podspecs(
    required_xcode_version: <xcode version from config json>
)
```