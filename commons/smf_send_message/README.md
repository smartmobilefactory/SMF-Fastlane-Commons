# smf_send_message

This lane sends a message to the configured Slack channel.

The default Channel is the one from the Config.json - if that one is not set an error Channel is used.

### Example
Sending a message.
```
smf_send_message(
    title: 'This is a bold title.',
    message: 'A kind message.',
    type: 'success', #Optional, by default the type is 'warning'
    slack_channel: 'ci-playground', #Optional, by default will post to the ci_error_log channel for each platform
    build_url: '', #Optional, by default the ENV['BUILD_URL'] is used
    exception: Exception('Example Exception'), #Optional
    additional_html_entries: [], #Optional
    fail_build_job_on_error: false, #Optional, false by default
)
```

## Exception
If an error occurs the error_info from the exception will be added to the message.

# smf_send_deprecation_warning

This lane can be used to send a deprecation warning. This warning will be displayed as a build error message (color style red) but it WILL NOT fail the build. Its just to raise more attention.

### Example

```
smf_send_deprecation_warning(
    title: "Use of deprecated phrase app scripts",
    message: "This projects uses deprecated phraseapp scripts!"
    estimated_time: "10m",
    requirements: ['Access to Project on PhraseApp', 'Access to something else']
)
```