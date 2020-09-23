## Monitor Unit Tests Results for iOS
This lane gather data and push the test results to an online database.

The date and the result of the lane `smf_ios_unit_tests` are taken.

Example:

```
smf_ios_monitor_unit_tests(
      project_name: <project_name>,		# Name of the project
      branch: <branch>,					# Name of the branch
      platform: <platform>,				# Name of the platform (iOS, macOS, tvOS, etc.)
      build_variant: <build_variant>    # Current build variant
  )
```