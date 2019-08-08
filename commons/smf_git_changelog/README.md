# smf_git_changelog

This lane collects the git commit messages into a changelog and stores it in *ENV[$SMF_CHANGELOG_ENV_KEY]*. In addition, the changelog will be stored formatted in HTML in *ENV[$SMF_CHANGELOG_ENV_HTML_KEY]*.

### Example
Getting the changelog between this commit and the last commit which tag contains *Alpha*.
```
smf_git_changelog(build_variant: 'Alpha')
```

## Collect commit messages
The commit messages will be collected by fetching the git commits between the last tag and *HEAD*. Merges are excluded.
The author's name will be removed and the first letter of the message will be capitalized.
Further, commits made by *SMFHUDSONCHECKOUT* will be ignored.

## No tag matches
If there is no matching tag the initial commit will be used for collecting the commits.

## Changelog is too long
If the changelog contains more than 20 000 characters it will be shortened.

