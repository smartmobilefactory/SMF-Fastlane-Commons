### Ensure correct xcode version

This lane ensures that the correct xcode version is set before the pod/app build starts.

Example Call:

```
smf_setup_correct_xcode_executable_for_build(
    required_xcode_version: "10.2" # The projects xcode version
)
```

If `required_xcode_version` is `nil` or empty (no `xcode_version` in `Config.json`), the lane
selects `/Applications/Xcode.app` and skips `ensure_xcode_version`. The project then builds with
whichever Xcode the node has installed under the default name.