## Run Unit Tests for iOS
This lane checks if unittests can be perforemed by calling `scan` with a `--dry-run` flag.
If this check is successful unit tests are preformed.

Example:

```
smf_ios_unit_tests(
      project_name: <project_name>,                                                 # Name of the project
      unit_test_scheme: <scheme_for_unit_tests>,                                    # Unit Test scheme name
      scheme: <current_scheme>,                                                     # Normal scheme used when Unit Test scheme is nil
      unit_test_xcconfig_name: <name_of_the_xcconfig_for_unit_tests>,               # Name of the xcconfig to use for the unit tests
      device: <test_device_name_to_test_against>,                                   # Name of the device to use for the unit tests
      get_required_xcode_version: "10.2",                                           # The xcode version used to build this project
      unit_testing_for_mac_os: false                                                # Optional, set to true if running unit tests for platform mac os
      skip_thread_sanitizer_for_unit_tests: <skip_thread_sanitizer_for_unit_tests>  # Skip Thread Sanitizer check for unit tests, false by default
  )
```