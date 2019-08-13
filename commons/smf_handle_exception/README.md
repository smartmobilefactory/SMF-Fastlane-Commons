# smf_handle_exception

This lane handles exceptions. For this reason a *name*(the project's name), a *message*, an *exception* and a *build_variant* can be provided in the options. While a *message* is optional, an  *exception* and a *build_variant* and a name must be given.
This lane contains also platform specific error handling like deleting an uploaded hockey entry on iOS.

### Example
Handle an exception.
```
smf_handle_exception(
    name: 'Example App Name',
    message: 'This is just an example',
    exception: Exception('Example'),
    build_variant: 'Alpha'
)
```

