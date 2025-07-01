# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

SMF-Fastlane-Commons is a collection of reusable Fastlane lanes and tools for mobile app development across iOS, Android, and Flutter platforms. This repository serves as a shared library that gets cloned into projects as a git submodule.

## Development Commands

This is a Ruby-based Fastlane project with no package.json or traditional build system. The primary way to work with this code is through Fastlane lanes:

```bash
# Test individual lanes (run from a project that uses these commons)
fastlane <lane_name>

# Example: Test iOS unit tests lane
fastlane smf_ios_unit_tests

# Test platform-specific setup
fastlane smf_setup_dependencies_pr_check
```

## Architecture and Structure

### Core Components

1. **Setup Files** (`setup/`): Platform-specific entry points that define the main lanes called by Jenkins
   - `apple_setup.rb` - iOS/macOS lanes
   - `android_setup.rb` - Android lanes  
   - `flutter_setup.rb` - Flutter lanes
   - `ios_framework_setup.rb` - iOS framework lanes

2. **Commons** (`commons/`): Reusable lane implementations organized by function
   - Platform-specific subdirectories (`ios/`, `android/`, `macos/`)
   - Shared functionality (`smf_build_app/`, `smf_git_changelog/`, etc.)
   - Reporting tools (`reporting/`)

3. **Fastlane Core** (`fastlane/`):
   - `Fastfile` - Main entry point with platform detection and commons importing
   - `utils/` - Shared utility functions
   - `APIs/` - External API integrations (GitHub, JIRA)
   - `constants/` - Global constants and environment variable keys

### Key Patterns

- **Naming Convention**: All custom functions/lanes start with `smf_` prefix
- **Private Functions**: Functions used only within a file are prefixed with `_smf_`
- **Platform Detection**: Uses `@platform` variable to determine iOS/Android/Flutter context
- **Configuration**: Reads from `Config.json` in the consuming project via `@smf_fastlane_config`

### Import System

The repository uses a dynamic import system based on platform:

1. `smf_import_commons` function determines platform from `@platform` variable
2. Clones/updates the commons repo to project-specific location:
   - iOS/macOS: `<workspace>/.fastlane-smf-commons`
   - Android/Flutter: `<workspace>/.idea/.fastlane-smf-commons`
3. Imports all Ruby files from commons, utils, APIs, and tools directories
4. Loads platform-specific setup file

### Configuration System

- Projects provide a `Config.json` file with build variants and settings
- Accessed via `@smf_fastlane_config` global variable
- Helper function `smf_config_get(build_variant, *keys)` for nested access
- Platform-specific required/optional keys defined in constants

### Common Lane Patterns

Most lanes follow this structure:
```ruby
private_lane :smf_example_lane do |options|
  # Extract all parameters to variables at the beginning
  build_variant = options[:build_variant]
  target_value = options[:target_value]
  
  # Lane implementation
  UI.message("Processing #{build_variant}")
  # ... lane logic
end
```

### Error Handling

- Global error handler in `Fastfile` sends failures to Slack channels
- Platform-specific error channels defined in constants
- Exception handling via `smf_handle_exception` lane

## Working with This Codebase

- Each lane/tool has its own directory with a README.md explaining usage
- When modifying lanes, update the corresponding README
- Follow the existing naming conventions and code style
- Test changes in a consuming project before committing
- Use single quotes over double quotes for strings
- Assign all lane parameters to variables at the beginning of functions