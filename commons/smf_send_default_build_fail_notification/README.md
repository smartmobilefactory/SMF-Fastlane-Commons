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
<img width="654" alt="Screenshot 2019-08-13 at 09 32 39" src="https://user-images.githubusercontent.com/40039883/62923121-5421bd80-bdad-11e9-8cc9-091113823856.png">
