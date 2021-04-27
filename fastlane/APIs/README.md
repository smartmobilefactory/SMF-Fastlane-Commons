# APIs

This folder is for APIs (Jira, Github, etc.) which are used across different lanes.

## Github

All functions are bundled in the file `smf_github_api`. Each function should start with the prefix: `smf_github`

| Function | Parameters | Description |
| :------- | :--------- | :---------- |
|`smf_github_fetch_pull_request_data`| `pr_number` : The number of the PR to fetch|Returns a map with the following entries: `body, title, commits, pr_link, branch`|


## Jira

All functions are bundled in the file `smf_jira_api`. Each function should start with the prefix: `smf_jira`

| Function | Parameters | Description |
| :------- | :--------- | :---------- |
|`smf_jira_fetch_ticket_data_for`| `ticket_tag` : The tag that identifies the ticket| Returns a map with the following entries: `base_url`  Base url of the ticket, `title`, `linked_tickets` : tickets which are linked to this ticket |
|`smf_jira_fetch_related_tickets_for`| `ticket_tag` : The tag that identifies the ticket. `base_url` : The base url of the ticket | Returns a list of maps with the following structure: `tag` : The tickets tag, `title` : The tickets title|