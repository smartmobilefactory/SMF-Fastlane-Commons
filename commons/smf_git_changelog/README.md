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

#### Custom Ticket Links
The base url which is used to create the ticket links defaults to `https://smartmobilefactory.atlassian.net` which is provided by the lane `smf_super_atlassian_base_urls`. If a project might contain tickets from other atlassian instances, new base urls can be added by overriding the lane `smf_atlassian_base_urls` in the projects Fastfile. For example if the project also contains tickets from the 'dokulino space' one could add the following lines to the projects fastfile:
```
override_lane :smf_atlassian_base_urls do
  smf_super_atlassian_base_urls + ['https://dokulinonext.atlassian.net']
end
```
**NOTE**: Make sure to always call the super lane and append your new values to it's result.

The array returned by `smf_atlassian_base_urls` is then used during the 'ticket lookup process'. For each found ticket tag, an API call is triggered using the provided base urls until a request is successful. This url is then used to create the ticket link and to get more detailed information about the ticket itself. If all API calls fail, the ticket is presented in the changelog's 'Unknown Tickets' section.

#### Ticket name blacklist
In the file `smf_ticket_detection_utils.rb`, an array is defined (`TICKET_BLACKLIST`) which contains regex's to match ticket names which should be ignored. For example the regex `UTF-*` prevents strings containing something like `UTF-16` from being counted as a valid ticket tag.

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