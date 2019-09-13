## Global Variables

The following variable are globally available in all lanes and functions:

| Variable | Type | Description |
|----------|------|-------------|
| `@fastlane_commons_dir_path`| String |  The directory path of the fastlane commons |
| `@smf_fastlane_config` | Map | Contains the projects Config.json. Keys are converted to symbols |
| `@platform` | Symbol | The current platform. This can be one of the following values: :ios, :android, :flutter  