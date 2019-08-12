# smf_send_default_build_fail_notification

This lane sends the default build fail notification via smf_send_message.

### Example
Sending an build fail notification.
```
smf_send_default_build_fail_notification(
    build_variant: 'Alpha',
    exception: Exception('An Exception.'),
    message: '', #Optional
)
```

