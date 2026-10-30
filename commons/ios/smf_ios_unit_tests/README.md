## Run Unit Tests for iOS
This lane checks if unittests can be perforemed by calling `scan` with a `--dry-run` flag.
If this check is successful unit tests are preformed.

Example:

```
smf_ios_unit_tests(
      project_name: <project_name>,                                     # Name of the project
      unit_test_scheme: <scheme_for_unit_tests>,                        # Unit Test scheme name
      scheme: <current_scheme>,                                         # Normal scheme used when Unit Test scheme is nil
      unit_test_xcconfig_name: <name_of_the_xcconfig_for_unit_tests>,   # Name of the xcconfig to use for the unit tests
      device: <test_device_name_to_test_against>,                       # Name of the device to use for the unit tests
      required_xcode_version: "26.6",                                   # The xcode version used to build this project
      unit_test_runner_xcode_version: "default",                        # Optional, the xcode that runs the tests: "default" or a version (see below)
      unit_testing_for_mac_os: false                                    # Optional, set to true if running unit tests for platform mac os
      use_thread_sanitizer: <use_thread_sanitizer>                      # Use Thread Sanitizer, true by default
  )
```
### Running the tests with a newer Xcode (RWCIT-2119)

On macOS 27.2 an Xcode 26.x can still build and archive, but it can no longer run simulator tests:
AMFI refuses its `DTServiceHub`, xcodebuild logs `DTServiceHubClient failed to bless service hub`
and the run ends with "The test runner hung before establishing connection".

A project that has to keep building with the older Xcode sets the optional project key in `Config.json`:

```json
"project": {
  "xcode_version": "26.6",
  "unit_test_runner_xcode_version": "default"
}
```

`"default"` runs the tests with the node's `/Applications/Xcode.app`, whatever version it is. That is
the recommended value: the runner only has to be accepted by the host macOS, and the default Xcode is
kept current with it, whereas a pinned runner version would need raising after every macOS update
that rejects it. A version such as `"27.2"` still works and pins the runner like `xcode_version` pins
the build.

The lane then runs `build-for-testing` with `xcode_version` — the app and the tests keep the
project's SDK — and `test-without-building` with `unit_test_runner_xcode_version`. Afterwards it
switches back to `xcode_version`. Without the key, or with the same version in both, nothing changes.
With a pinned version the node needs `/Applications/Xcode-<unit_test_runner_xcode_version>.app`.
