# smf_increment_version_number

This lane increments the version number of the project if a library is built and returns the new tag.

### Example
Increment the version number.
```
smf_increment_version_number(
    podspec_path: <path to pods podspec file>
    bump_type: <either major, minor, current, patch, breaking or internal>
    additional_podspecs: <array with additional podspec paths>
)
```

## bump_type
There are five possible bump types:<br />

| bump type  | description                                          | example            |
| ---------- | ---------------------------------------------------- | ------------------ |
| major      | Increments the first part of the version number.     | 1.2.3 -> 2.0.0     |
| minor      | Increments the second part of the version number.    | 1.2.3 -> 1.3.0     |
| patch      | Increments the third part of the version number.     | 1.2.3 -> 1.2.4     |
| breaking   | Like patch and sets last part to 0.                  | 1.2.3.4 -> 1.2.4.0<br />1.2.3 -> 1.2.4.0 |
| internal   | Increments the last part.                            | 1.2.3.4 -> 1.2.3.5<br />1.2.3 -> 1.2.3.1 |
| current    | The version number is not changed.                   | 1.2.3.4 -> 1.2.3.4 |

"current" is used when the version number is set manually and shouldn't be changed by fastlane.

## Create new tag
The current build number will be incremented and used for the new tag. If this tag exists the build number will be incremented again the same way. This process will run ten times if needed. 


# smf_incremented_version_number_dry_run

This lane increments the version number in the podspec file and returns it, but then discards the changes. It can be used to get the version number which would be set if the version was actually increased.

### Example

```
smf_increment_version_number_dry_run(
    podspec_path: <path to pods podspec file>
    bump_type: <either major, minor, current, patch, breaking or internal>
)
```