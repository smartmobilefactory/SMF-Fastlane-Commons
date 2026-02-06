# smf_run_linter

This lanes run linter tasks by using gradle. All lanes call *smf_danger_module_config* with the given options do get the danger module config.

### Example for detekt
```
smf_run_detekt(
    modules: [] # Optional, see *smf_danger_module_config* for further information
)
```

### Example for lint
```
smf_run_gradle_lint_task(
    build_variant: 'alpha',     #Optional, by default all lint task will be executed
    modules: []                 # Optional, see *smf_danger_module_config* for further information
)
```

### Example for junit task
```
smf_run_junit_task
```

### Example for klint
```
smf_run_klint(
    modules: [] # Optional, see *smf_danger_module_config* for further information
)
```

## smf_danger_module_config

This lanes returns an array of modules. If *modules* are given these modules will be returned unmodified. If *modules* are not specified a module with *module_basepath*, *run_detekt*, *run_klint*, *junit_task* will be added to the returned array.

## Example

```
smf_danger_module_config(
    modules: [],                #Optional, by default and if this array is empty a new module with the given parameters will be added to the returned array. If modules are given these will be returned unmodified.
    module_basepath: '',        #Optional, by default ''
    run_detekt: true,           #Optional, by default true
    run_klint = true,           #Optional, by default true
    junit_task: <junit_task>    #Optional, by default no unit task will be executed
)
```

## smf_run_swift_lint

**Status:** Deprecated/Simplified (as of CBENEFIOS-2070)

This lane is now a no-op. Projects should use SwiftLint via **SPM Build Tool Plugin** instead.

### Modern SwiftLint Setup (Required for new projects):

1. **Add SwiftLintPlugins as SPM dependency:**
   - In Xcode: File → Add Package Dependencies
   - URL: `https://github.com/SimplyDanny/SwiftLintPlugins`
   - Version: Latest (e.g., 0.63.x)

2. **Enable Build Tool Plugin:**
   - Select target → Build Phases
   - Add "Run Build Tool Plug-ins"
   - Select "SwiftLintBuildToolPlugin"

3. **Commit `.swiftlint.yml` configuration:**
   - Create project-specific SwiftLint rules
   - Remove `.swiftlint.yml` from `.gitignore`
   - Commit the configuration file

### Benefits:
- ✅ No external SwiftLint installation required
- ✅ Version fixed in project (reproducible builds)
- ✅ Works automatically for all developers and CI
- ✅ Warnings visible directly in Xcode
- ✅ PR comments via danger-swiftlint

### For PR checks:
SwiftLint is run directly by danger-swiftlint (no XML files needed).
See `commons/smf_danger/Dangerfile` for implementation.

Example (legacy compatibility):
```ruby
smf_run_swift_lint  # Shows informational message
```

## smf_run_flutter_analyzer

This lane runs the flutter command 'analyze' and saves the output to a .xml file.

Example:
```
smf_run_flutter_analyzer
```