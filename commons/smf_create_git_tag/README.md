# smf_create_git_tag

This lane creates a new tag on GitHub.

### Example
Create the first alpha tag:
```
smf_create_git_tag(
    build_variant: "alpha",     # The build variant of the tag.
    build_number: 1             # The build number of the tag.
)
``` 
The new tag looks like this: "build/alpha/1".