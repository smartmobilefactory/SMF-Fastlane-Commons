# smf_git_changelog

This lane collects the git commit messages into a changelog and stores it using *smf_write_changelog*.

### Example
Getting the changelog between this commit and the last commit which tag contains *Alpha*.
```
smf_git_changelog(
    build_variant: 'Alpha',
    is_library: false, #Optional, by default false
)
```

#### Result by changelog_from_git_commits
<img width="781" alt="Screenshot 2019-08-13 at 09 02 50" src="https://user-images.githubusercontent.com/40039883/62922458-b11c7400-bdab-11e9-8835-7310b8fc08bc.png">

#### Stored Result
The author's name will be removed and the first letter of the message will be capitalized.
Further, commits made by *SMFHUDSONCHECKOUT* will be ignored.
Then the changelog is searched for ticket tags. These tags are then used to generate a second changelog section which contains all tickets related to this release.
To conveniently format the changelog, there are some helper functions in the `smf_changelog_formatter.rb` file.

## Collect commit messages
The commit messages will be collected by fetching the git commits between the last tag and *HEAD*. If an app is built the last tag is the tag which contains the *build_variant*. If a library is built, the parameter *is_library* must be set to true. In this case the last tag is the last one which starts with *releases/*. Merges are excluded.

## No tag matches
If there is no matching tag the initial commit will be used for collecting the commits.

## Changelog is too long
If the changelog contains more than 20 000 characters it will be shortened.


# Global Changelog Availability With a Temporary Changelog File
### Reading
The private lane `smf_read_changelog` reads the temporary changelog file and returns the changelog as a string.
If the flag `hmtl` is set to true,  the html formatted changelog file is read and returned instead.

Example: 

```
changelog = smf_read_changelog()
```

```
changelog = smf_read_changelog(html: true) # returns the html formatted changelog
```

### Writing
The private lane `smf_write_changelog` writes a given string to the temporary changelog file. The file is complete overwritten. Additionally the changelog in html format can be written to a second file, too.

Exampel:

```
changelog = smf_write_changelog(
    changelog: "Some commit messages"  # The changelog which will be written to the file
    html_changelog: "<b> Changelog as HTML </b>" # The changelog formatted in html
)
```