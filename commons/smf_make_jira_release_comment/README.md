# smf_make_jira_release_comment

Writes a `Released in <app name and version>` comment onto every ticket of the
build's changelog. The lane is called from `smf_super_push_git_tag_release`, so
it runs for every tagged build of every build variant.

## Which tags are commented on

The lane reads the ticket tags the changelog stored and posts to the **first**
configured Atlassian instance — the one `smf_jira_add_comment_to_ticket` uses.
Three kinds of tag are skipped, because a POST for them can only ever come back
as a 404 (RWCIT-2127):

| Skipped | Why |
|:--|:--|
| `PR-<number>` | A pull request reference, never a Jira ticket |
| Tags no instance knows | Nothing behind them — typically a key-shaped string from a PR body |
| Tags of another instance | The ticket exists, but not where the comment would be posted |

The lookup that decides this is served from the per-build API cache the
changelog already filled (`fastlane/APIs/smf_api_cache.rb`), so the check costs
no additional request.

Which instance receives the comment is deliberately unchanged: resolving a
ticket on a second instance and commenting there would create comments where a
project has never had any.

## Switching it off

Nothing reads these comments back, and on a project with many build variants
they accumulate quickly — one comment per ticket per variant per build. A
project that does not want them overrides the lane in its own `Fastfile`:

```ruby
override_lane :smf_make_jira_realease_comment do |options|
  UI.message("Skipping the Jira release comment for #{options[:build_variant]}")
end
```
