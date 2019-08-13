# smf_send_default_build_success_notification

This lane sends the default build success notification via smf_send_message. The message will contain the changelog.

### Example
Sending an build success notification.
```
smf_send_default_build_success_notification(
    build_variant: 'Alpha',
)
```

<img width="663" alt="Screenshot 2019-08-13 at 09 06 41" src="https://user-images.githubusercontent.com/40039883/62922459-b11c7400-bdab-11e9-938a-0e20dd5e0bcd.png">
