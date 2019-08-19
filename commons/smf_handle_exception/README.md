# smf_handle_exception

This lane handles exceptions. For this reason a *name*(the project's name), a *message* and an *exception* can be provided in the options. While a *message* is optional, an  *exception* and a *name* must be given.
This lane contains also platform specific error handling like deleting an uploaded hockey entry on iOS.

### Example
Handle an exception.
```
smf_handle_exception(
    name: 'Example App Name',
    message: 'This is just an example',
    exception: Exception('Example')
)
```

