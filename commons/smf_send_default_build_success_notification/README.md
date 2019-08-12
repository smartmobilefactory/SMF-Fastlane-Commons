# smf_send_default_build_success_notification

This lane sends the default build success notification via smf_send_message. The message will contain the changelog.

### Example
Sending an build success notification.
```
smf_send_default_build_success_notification(
    build_variant: 'Alpha',
)
```