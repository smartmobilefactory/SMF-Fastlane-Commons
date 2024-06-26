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

This lane runs SiwftLint and stores the output in the `<project>/build` folder.
SwiftLint is configured with the swiftlint.yml in this directory.

It also generates a report of the default opt-in rules that have not been integrated or reviewed.

Example:

```
smf_run_swift_lint
```

## smf_run_flutter_analyzer

This lane runs the flutter command 'analyze' and saves the output to a .xml file.

Example:
```
smf_run_flutter_analyzer
```