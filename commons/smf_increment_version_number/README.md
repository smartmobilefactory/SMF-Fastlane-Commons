# smf_increment_version_number

This lane increments the version number of the project if a library is built and returns the new tag.

### Example
Increment the version number.
```
smf_increment_version_number(
    podspec_path = options[:podspec_path],
    bump_type = options[:bump_type]
)
```

## bump_type
There are five possible bump types:<br />
    "major": Increments the first part of the version number.<br />
    "minor": Increments the second part of the version number.<br />
    "patch": Increments the last part if the version number.<br />
    "breaking": In case the versionning is as following: major.minor.breaking.internal "breaking" will increment the third part and set the last part to 0.<br />
    "internal": In case the versionning is as following: major.minor.breaking.internal "internal" will set the last part to the incremented fourth part if there are 4 or more parts.<br />
    
"mayor" and "minor" are usually set manually. "breaking" and "internal" are only incremented via Fastlane.

## Create new tag
The current build number will be incremented and used for the new tag. If this tag exists the build number will be incremented again the same way. This process will run ten times if needed. 