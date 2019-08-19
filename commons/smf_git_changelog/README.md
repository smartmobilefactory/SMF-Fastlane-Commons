# smf_git_changelog

This lane collects the git commit messages into a changelog and stores it in *ENV[$SMF_CHANGELOG_ENV_KEY]*. In addition, the changelog will be stored formatted in HTML in *ENV[$SMF_CHANGELOG_ENV_HTML_KEY]*.

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
<img width="663" alt="Screenshot 2019-08-13 at 09 06 41" src="https://user-images.githubusercontent.com/40039883/62922459-b11c7400-bdab-11e9-938a-0e20dd5e0bcd.png">

## Collect commit messages
The commit messages will be collected by fetching the git commits between the last tag and *HEAD*. If an app is built the last tag is the tag which contains the *build_variant*. If a library is built, the parameter *is_library* must be set to true. In this case the last tag is the last one which starts with *releases/*. Merges are excluded.

## No tag matches
If there is no matching tag the initial commit will be used for collecting the commits.

## Changelog is too long
If the changelog contains more than 20 000 characters it will be shortened.

