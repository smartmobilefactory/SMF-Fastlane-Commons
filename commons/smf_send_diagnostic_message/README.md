### Send Diagnostic messages

This lane can be used to send messages to the 'ci-diagnostic-messages' channel. This can be useful to test fastlane features that are not 'live' yet and log errors and data to this channel.

Example: 

```
smf_send_diagnostic_message(
    title: <Message title>,     # This should describe which 'feature' issued this message
    message: <Message body>     # Useful data/errors/diagnostics to analyse the performance of the feature
```