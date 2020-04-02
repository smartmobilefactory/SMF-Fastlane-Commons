## Sparkle Package Creator
This tool can be used to create a sparkle package (appcast, release html, app's dmg) for an already signed app dmg. Therefore it needs the path to the .dmg and the build variant. This is needed, because for Example for a MagentaCLOUD Live release the flow is the following: 
- We are building an unsigned DMG (with the normal macOS build job)
- The customer is resigning and notarizing the DMG, and send it back to us
- We create the Sparkle package, and send it back to them.

When creating a Sparkle Package with this tool, a release is created and upload to [this](https://github.com/smartmobilefactory/SMF-Sparkle-Packages-Container) repository. Then the package is attached to the release conforming to the following naming scheme: <project_name>-<build_variant>-<build_number>.zip. **Example**: HiDrive-hidrive_alpha-1395.zip

The release tag is composed of the project name, build-variant and build number.
                                                                                                                                                                                              
Example

```
smf_create_sparkle_package(
    build_variant: <build_variant>,
    dmg_path: <path to dmg>
)
```
### How to setup Sparkle Package Creator for a new macOS Project
To use this package creator in a macOS project, you have to setup a custom build job. The jenkins file to use is this one:

```
//
// Automatically generated. Do not edit.
//

@Library('jenkins-pipeline-commons@migration_fastlane_commons') _

_build_variants = []

_build_parameters = [
	'build_variants': _build_variants
]

sparklePackageCreator(_build_parameters)
``` 
which should be name `Sparkle-Package-Creator-Jenkinsfile` and be places in new folder `<projects_root_director>/Sparkle-Package-Creator` inside the project.

Furthermore to keep the available build_variants up to date, the projects fastfile should override the `smf_generate_files` lane with the following:

```
override_lane :smf_generate_files do | options |
  UI.message("NOTE: This is a custom lane. See projects fastfile for information.")

  sparkle_package_creator_data = {
    :file => _smf_spc_jenkinsfile_path,
    :template => _smf_spc_template_path,
    :remove_multibuilds => true
  }

  smf_super_generate_files(files_to_update: [sparkle_package_creator_data])
end
``` 

This will ensure, that the build_variants are also generated into the new sparkle package creator jenkinsfile. On every new PR it is checked and generated if something changed. Note however, that regenerating this sparkle package creator jenkins file does not cause the pull request to restart, because it is not needed for the pull request.

