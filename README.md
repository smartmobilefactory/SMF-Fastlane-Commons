# SMF-Fastlane-Commons

# Get Started
The SMF-Fastlane-Commons are a set of all Fastlane lanes we use for our PR checks and builds 👷‍♀️👷‍♂️

In the 'setup' directory we placed a setup file for every platform. In these setup files we put all lanes that are called by Jenkins. The defined lanes call the common lanes, which we place in the 'commons' directory. There you can find all lanes we use. Each lane has it's own directory and a README for better understanding 💡 Platform specific lanes will be Subdirectories of the corresponding directory like 'ios'.

To keep up this structure we follow the following guidelines.

* [Add or update a lane](#Add or update a lane)
* [Passing Naming of lanes and functions to lanes](#Naming of lanes and functions)
* [Passing values to lanes](#Passing values to lanes)
* [Frequently used variables](#Frequently used variables)
* [Constants](#Constants)

## Add or update a lane
If we edit a lane's parameter we always **update the README** and if we do major changes to a lane we should **update the README in the setup directory**. 

## Naming of lanes and functions
Every lane and function we define starts with **smf\_**, because want to see the distinguish our code from the Fastlane code. If we use a function just in one file we mark it with **_** to make clear that it is only used in this file. Otherwise, we put it in the **utils.rb** file.
```
def _smf_helper(parameter1, parameter2)
    # Returns parameter1, super helpful!
    parameter1
end

```
## Passing values to lanes
 We pass values e.g. from the **config.json** or jenkins are passed as parameters. We assign **all parameters to variables** at the beginning of a lane.
### Example
*example_lane.rb*
```
private_lane :smf_example_lane do |options|
	test_value = options[:test_value]
	UI.message(“Log: #{test_value}.”)
end
```

*example_setup.rb*
```
private_lane :smf_super_example_lane_in_setup do |options|
	# Read values from config.json or jenkins here
    value = @smf_fastlane_config[:value_key]
	example_lane(
		test_value: value
	)
end

lane :smf_example_lane_in_setup do |options|
    # Remove () if you do not pass parameters
    smf_super_example_lane_in_setup
end
```

## Frequently used variables
**@smf_fastlane_config**: [Access the config.json](#Passing values to lanes).
**@platform**: Helps us finding out for which platform we are running fastlane.
**@fastlane_commons_dir_path**: Represents the path to the fastlane-smf-commons in the project.
**smf_workspace_dir**: Is a function which returns the workspace directory and is often used to get the path to sth.
*Example*
```
def smf_import_commons

  case @platform
  when :ios, :ios_framework, :macos
    @fastlane_commons_dir_path = "#{smf_workspace_dir}/.fastlane-smf-commons"
  when :android
    @fastlane_commons_dir_path = "#{smf_workspace_dir}/.idea/.fastlane-smf-commons"
  when :flutter
    @fastlane_commons_dir_path = "#{smf_workspace_dir}/.idea/.fastlane-smf-commons"
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    # Prefer single quotes over double quotes.
    raise 'Unknown Platform'
  end
  ...
end
```

## Constants
We define globally used constants in the 'Constants.rb' file. Local constants should be initialized at the beginning of the lane.
