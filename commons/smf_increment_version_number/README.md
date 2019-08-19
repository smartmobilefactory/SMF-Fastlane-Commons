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

| bump type  | description                                          | example            |
| ---------- | ---------------------------------------------------- | ------------------ |
| major      | Increments the first part of the version number.     | 1.2.3 -> 2.0.0     |
| minor      | Increments the second part of the version number.    | 1.2.3 -> 1.3.0     |
| patch      | Increments the third part of the version number.     | 1.2.3 -> 1.2.4     |
| breaking   | Like patch and sets last part to 0.                  | 1.2.3.4 -> 1.2.4.0<br />1.2.3 -> 1.2.4.0 |
| internal   | Increments the last part.                            | 1.2.3.4 -> 1.2.3.5<br />1.2.3 -> 1.2.3.1 |
    
"mayor" and "minor" are usually set manually. "breaking" and "internal" are only incremented via Fastlane.

## Create new tag
The current build number will be incremented and used for the new tag. If this tag exists the build number will be incremented again the same way. This process will run ten times if needed. 
