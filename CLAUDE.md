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

## Version Code Management (Android)

### Overview (CBENEFIOS-1881)

Since November 2025, Android builds use **Git tags as the source of truth** for version codes instead of committing Config.json on every build. This eliminates 18-54 commits per week across all client projects.

### New Module: `smf_version_management`

**Location:** `commons/smf_version_management/smf_get_next_version_code.rb`

**Functions:**

1. **`smf_get_next_version_code_from_tags(platform)`**
   - Queries all Git tags matching `build/*/*` pattern
   - Extracts highest version code
   - Returns `highest + 1`
   - Fallback to Config.json if no tags exist

2. **`smf_is_ci?()`**
   - Detects CI environment (Jenkins, GitHub Actions, etc.)
   - Checks for `BUILD_NUMBER`, `CI`, `JENKINS_HOME` environment variables

3. **`smf_get_current_version_code_from_apk(apk_path)`**
   - Extracts version code from built APK using `aapt`
   - Used for Git tag creation after build

### Modified Lanes

**`smf_super_build` (setup/android_setup.rb):**
```ruby
# CI: Use Git tags for version code
if smf_is_ci?
  version_code = smf_get_next_version_code_from_tags('android')
else
  version_code = @smf_fastlane_config[:app_version_code]
end

smf_build_android_app(
  build_variant: variant,
  keystore_folder: keystore_folder,
  version_code: version_code  # NEW parameter
)
```

**`smf_build_android_app` (commons/smf_build_app/smf_build_android_app.rb):**
- Now accepts optional `version_code` parameter
- Passes version code to Gradle as property
- Project must support `project.hasProperty("versionCode")` in build.gradle.kts

**`smf_super_pipeline_increment_build_number` (setup/android_setup.rb):**
- Now skips Config.json increment for CI builds (no-op)
- Only increments for local builds
- Marked as deprecated for CI use

**`smf_super_pipeline_create_git_tag` (setup/android_setup.rb):**
- CI: Extracts version code from built APK (not Config.json)
- Fallback to Git tags if extraction fails
- Local: Uses Config.json (backward compatible)

### Usage in Client Projects

**build.gradle.kts:**
```kotlin
versionCode = if (project.hasProperty("versionCode")) {
    project.property("versionCode").toString().toInt()  // From Fastlane
} else {
    (configJson?.get("app_version_code") as? Int) ?: 1  // Fallback
}
```

**Jenkins Jobs:**
- Can stop calling `smf_pipeline_increment_build_number` lane
- Version code is automatically managed via Git tags
- No Config.json commits needed

### Benefits

- **Before:** 18-54 Config.json commits per week (9 countries × 2-6 builds each)
- **After:** 0 Config.json commits, only lightweight Git tags
- **Backward Compatible:** Local builds still use Config.json
- **Sequential:** Version codes remain sequential and unique

### Git Tag Format

```
build/android/{variant}/{versionCode}

Examples:
build/android/de_alpha/3549
build/android/tr_beta/3550
build/android/it_live/3551
```

### Troubleshooting

**Version code not incrementing:**
- Check Git tags: `git tag -l 'build/*/*' | sort -V | tail -10`
- Ensure tags are pushed to remote
- Verify `smf_is_ci?` returns true in CI environment

**Config.json still being committed:**
- Verify SMF-Fastlane-Commons is updated to latest version
- Check that `smf_pipeline_increment_build_number` is not called by Jenkins
- CI environment detection should work automatically

## Working with This Codebase

- Each lane/tool has its own directory with a README.md explaining usage
- When modifying lanes, update the corresponding README
- Follow the existing naming conventions and code style
- Test changes in a consuming project before committing
- Use single quotes over double quotes for strings
- Assign all lane parameters to variables at the beginning of functions