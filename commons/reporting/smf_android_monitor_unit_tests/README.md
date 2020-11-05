## Monitor Unit Tests Results for Android
This lane gather data and push the test results to an online database.

The date and the result of the lane `smf_run_junit_task` are taken.

Example:

```
smf_android_monitor_unit_tests(
    project_name: <project_name>,		# Name of the project
    branch: <branch>					# Name of the branch
)
```