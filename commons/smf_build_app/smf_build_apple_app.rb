private_lane :smf_build_apple_app do |options|

  UI.important("Creating the Xcode archive")

  # clean build directory
  UI.message('Cleaning build directory')
  `rm -rf #{smf_workspace_dir}/build`

  # Clean global DerivedData for this project to prevent stale artifacts
  # This fixes sporadic ibtool/CompileStoryboard failures after deployment target changes
  UI.message('Cleaning global DerivedData for CorporateBenefits')
  `rm -rf ~/Library/Developer/Xcode/DerivedData/CorporateBenefits*`

  # Parameter
  skip_package_ipa = (options[:skip_export].nil? ? false : options[:skip_export])
  skip_package_pkg = (options[:skip_package_pkg].nil? ? true : options[:skip_package_pkg])
  bulk_deploy_params = options[:bulk_deploy_params]
  scheme = options[:scheme]
  should_clean_project = options[:should_clean_project]
  required_xcode_version = options[:required_xcode_version]
  project_name = options[:project_name]
  xcconfig_name = options[:xcconfig_name]
  code_signing_identity = options[:code_signing_identity]
  upload_itc = options[:upload_itc].nil? ? false : options[:upload_itc]
  upload_bitcode = options[:upload_bitcode].nil? ? true : options[:upload_bitcode]
  export_method = options[:export_method]
  icloud_environment = options[:icloud_environment]
  workspace = options[:workspace]
  build_variant = options[:build_variant]
  build_number = options[:build_number]
  bundle_identifier = options[:bundle_identifier]
  match_type = options[:match_type]

  # CBENEFIOS-1900: Derive export_method from match_type if not explicitly set
  if export_method.nil? && match_type
    export_method = case match_type.to_s.downcase
                    when 'adhoc' then 'ad-hoc'
                    when 'appstore' then 'app-store'
                    when 'development' then 'development'
                    when 'enterprise' then 'enterprise'
                    when 'developer_id' then 'developer-id'
                    else nil
                    end
    UI.message("📦 Derived export_method '#{export_method}' from match_type '#{match_type}'") if export_method
  end

  catalyst_platform = nil
  if @platform == :apple
    catalyst_platform = 'ios'
    catalyst_platform = 'macos' if smf_is_catalyst_mac_build(build_variant)
  end

  output_name = scheme

  # Check if the project defined if the build should be cleaned. Other wise the default behavior is used based on the whether the archiving is a bulk operation.
  clean_project = !bulk_deploy_params.nil? ? (bulk_deploy_params[:index] == 0 && bulk_deploy_params[:count] > 1) : true

  clean_project = should_clean_project if should_clean_project != nil

  unlock_keychain(path: "jenkins.keychain", password: ENV[$KEYCHAIN_JENKINS_ENV_KEY]) if smf_is_keychain_enabled

  smf_setup_correct_xcode_executable_for_build(required_xcode_version: required_xcode_version)

  # Build xcargs string with optional build number override (CBENEFIOS-2077)
  # Limit parallel jobs to prevent race conditions in actool/ibtool (CI stability fix)
  xcargs_string = "#{smf_xcargs_for_build_system} CODE_SIGN_STYLE=Manual -skipPackagePluginValidation -jobs 4"

  # CBENEFIOS-2193: Use shared compilation cache across all workspaces on the same node
  # Default path lands inside build/derivedData/ which gets deleted before each build.
  # Redirecting to a global path enables cache hits across parallel builds and slots.
  xcargs_string += " COMPILATION_CACHE_CAS_PATH=#{File.expand_path('~/Library/Developer/Xcode/CompilationCache')}"

  # CBENEFIOS-2157: CI Build Flags optimization
  if smf_is_ci?
    # Disable Index Store on CI (not needed without IDE, saves ~30-60s)
    xcargs_string += " COMPILER_INDEX_STORE_ENABLE=NO"

    # Alpha/Beta: use incremental compilation without optimization (saves ~30-60s)
    is_release = build_variant && (build_variant.include?('release') || build_variant.include?('live'))
    unless is_release
      xcargs_string += " SWIFT_COMPILATION_MODE=incremental"
    end
  end
  if build_number
    UI.message("🔢 Overriding CURRENT_PROJECT_VERSION with: #{build_number}")
    xcargs_string += " CURRENT_PROJECT_VERSION=#{build_number}"
  end

  # CBENEFIOS-2059: Determine provisioning profile name and update Xcode project
  # We use update_code_signing_settings instead of xcargs PROVISIONING_PROFILE_SPECIFIER
  # because xcargs applies to ALL targets including SPM packages, which don't support provisioning profiles
  profile_name = nil
  # Collected below and merged into the export options: without them the IPA
  # export fails the same way the build did, only later.
  extension_profiles = {}
  if bundle_identifier && match_type
    team_id = smf_config_get(build_variant, :team_id)

    # Hoisted out of the fallback branch below: extensions need the same naming
    # rule, and computing it twice is how the two drift apart.
    type_name_for_match = case match_type.to_s.downcase
                          when 'adhoc' then 'AdHoc'
                          when 'appstore' then 'AppStore'
                          when 'development' then 'Development'
                          when 'enterprise' then 'InHouse'
                          when 'developer_id' then 'Direct'
                          else match_type.to_s.split('_').map(&:capitalize).join('')
                          end
    # Match sets ENV variables in format: sigh_<bundle_id>_<type>_profile-name
    # Example: sigh_com.corporatebenefits.de.alpha_adhoc_profile-name
    profile_env_key = "sigh_#{bundle_identifier}_#{match_type}_profile-name"
    profile_name = ENV[profile_env_key]

    if profile_name && !profile_name.empty?
      UI.message("🔐 Using provisioning profile from match ENV: #{profile_name}")
    else
      # The ENV is gone whenever match ran in another process — since RWCIT-2102
      # it has its own pipeline stage — and for skip_match. Look at what is
      # installed before guessing: the portal appends a timestamp when a name is
      # taken ("match AdHoc <id> 1787520201"), and the bare name then matches
      # nothing, so the archive stops at "No profile ... matching".
      profile_name = _smf_installed_match_profile_name(type_name_for_match, bundle_identifier, team_id)
      if profile_name
        UI.message("🔐 Using installed provisioning profile: #{profile_name}")
      else
        # Match always uses naming convention: "match <Type> <bundle_identifier>"
        profile_name = "match #{type_name_for_match} #{bundle_identifier}"
        UI.message("🔐 Using constructed provisioning profile name: #{profile_name}")
      end
    end

    # Determine project path (handle workspace vs project scenarios)
    project_path = "#{project_name}.xcodeproj"
    if workspace && !workspace.empty?
      # Extract project path from workspace path for Flutter/workspace scenarios
      workspace_dir = File.dirname(workspace)
      potential_path = "#{workspace_dir}/#{project_name}.xcodeproj"
      project_path = potential_path if File.exist?(potential_path)
    end

    # Fall back to parent directory: when fastlane is invoked from the
    # `fastlane/` sub-directory rather than the project root, relative paths
    # resolve against `iosApp/fastlane/` and miss the .xcodeproj that lives
    # one level up. Try the parent before giving up. Use an absolute path
    # because update_code_signing_settings rejects relative paths starting
    # with "..".
    unless File.exist?(project_path)
      parent_path = File.expand_path("../#{project_path}")
      project_path = parent_path if File.exist?(parent_path)
    end

    if File.exist?(project_path)
      UI.message("🔧 Updating code signing settings in Xcode project: #{project_path}")

      # Which targets carry which identifier, read from the project rather than
      # guessed from the scheme.
      #
      # This matters because update_code_signing_settings *sets*
      # PRODUCT_BUNDLE_IDENTIFIER rather than filtering on it: a call without
      # `targets` rewrites the identifier and the profile of every target in the
      # project. With an App Clip or any other extension present, the extension is
      # then signed with the app's profile and the build stops at
      #
      #   Provisioning profile "match AdHoc <app>" doesn't include the App Clip
      #   capability. (in target '<app>Clip')
      #
      # Resolving by identifier keeps this working for projects that name their
      # targets freely. If nothing resolves, the original unfiltered call is used,
      # so no existing build changes behaviour.
      targets_carrying = lambda do |identifier|
        begin
          require 'xcodeproj'
          Xcodeproj::Project.open(project_path).targets.select { |target|
            target.build_configurations.any? { |config|
              config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] == identifier
            }
          }.map(&:name)
        rescue StandardError => e
          UI.important("⚠️  Could not read targets from #{project_path}: #{e.message}")
          []
        end
      end

      app_targets = targets_carrying.call(bundle_identifier)

      if app_targets.empty?
        UI.important("⚠️  No target carries #{bundle_identifier} — updating all targets, as before")
        update_code_signing_settings(
          path: project_path,
          use_automatic_signing: false,
          bundle_identifier: bundle_identifier,
          profile_name: profile_name,
          code_sign_identity: code_signing_identity
        )
      else
        update_code_signing_settings(
          path: project_path,
          use_automatic_signing: false,
          targets: app_targets,
          bundle_identifier: bundle_identifier,
          profile_name: profile_name,
          code_sign_identity: code_signing_identity
        )

        # Extensions carry their own identifier and their own profile. match has
        # already fetched them — smf_download_provisioning_profiles builds the same
        # identifiers from extensions_suffixes — but until here nothing applied
        # them to a target.
        extension_suffixes = smf_config_get(build_variant, :extensions_suffixes)
        extension_suffixes = smf_config_get(nil, :extensions_suffixes) if extension_suffixes.nil?

        (extension_suffixes || []).each do |suffix|
          extension_identifier = "#{bundle_identifier}.#{suffix}"
          extension_targets = targets_carrying.call(extension_identifier)

          if extension_targets.empty?
            UI.important("⚠️  No target carries #{extension_identifier} — skipping")
            next
          end

          extension_profile = ENV["sigh_#{extension_identifier}_#{match_type}_profile-name"]
          if extension_profile.nil? || extension_profile.empty?
            extension_profile = _smf_installed_match_profile_name(type_name_for_match, extension_identifier, team_id) ||
                                "match #{type_name_for_match} #{extension_identifier}"
          end

          UI.message("🔐 #{extension_identifier} → #{extension_profile}")

          update_code_signing_settings(
            path: project_path,
            use_automatic_signing: false,
            targets: extension_targets,
            bundle_identifier: extension_identifier,
            profile_name: extension_profile,
            code_sign_identity: code_signing_identity
          )

          extension_profiles[extension_identifier] = extension_profile
        end
      end
    else
      UI.important("⚠️  Project not found at #{project_path} - skipping update_code_signing_settings")
    end
  else
    UI.message("ℹ️  bundle_identifier or match_type not provided - using Xcode project defaults")
  end

  # Build export_options with provisioning profile mapping (for IPA export)
  export_opts = { iCloudContainerEnvironment: icloud_environment }
  if bundle_identifier && profile_name
    export_opts[:provisioningProfiles] = { bundle_identifier => profile_name }.merge(extension_profiles)
  end

  gym_parameters = {
    clean: clean_project,
    workspace: !workspace.nil? ? workspace : "#{project_name}.xcworkspace",
    scheme: scheme,
    configuration: xcconfig_name,
    codesigning_identity: code_signing_identity,
    output_directory: $IOS_BUILD_OUTPUT_DIR,
    xcargs: xcargs_string,
    archive_path: $IOS_ARCHIVE_PATH,
    derived_data_path: $IOS_DERIVED_DATA_PATH,
    cloned_source_packages_path: smf_source_packages_path(xcargs_string),
    result_bundle: true,
    result_bundle_path: $IOS_RESULT_BUNDLE_PATH,
    buildlog_path: $IOS_ARCHIVE_BUILD_LOGS_DIRECTORY,
    output_name: output_name,
    include_symbols: true,
    include_bitcode: (upload_itc && upload_bitcode),
    export_options: export_opts,
    export_method: export_method,
    skip_package_ipa: skip_package_ipa,
    skip_package_pkg: skip_package_pkg,
    catalyst_platform: catalyst_platform
  }

  gym_parameters[:destination] = 'platform=macOS,variant=Mac Catalyst' if smf_is_catalyst_mac_build(build_variant)

  gym(gym_parameters)

end

# RWCIT-2102: the node-wide package cache (~/spm-cache-persistent, CBENEFIOS-2156) is gone.
# Builds running at the same time on one node overwrote each other's packages in it.
# Packages now live per workspace in $IOS_SOURCE_PACKAGES_PATH, see smf_source_packages_path.
def smf_xcargs_for_build_system
  smf_is_using_old_build_system ? "" : "-UseNewBuildSystem=YES CODE_SIGN_STYLE=Manual"
end

# Returns the directory xcodebuild clones Swift packages into, or nil when the given
# xcargs already pass one (a project overriding smf_xcargs_for_build_system);
# xcodebuild rejects -clonedSourcePackagesDirPath twice.
#
# On Jenkins the packages live next to the workspace (<workspace>@spm-cache), not inside
# the project: linters such as a SwiftLint build phase without exclusions would otherwise
# lint every package (RKI iOS #42), and git clean never has to know about it.
# Jenkins-Pipeline-Commons (spmSeed.groovy) uses the same path.
def smf_source_packages_path(xcargs)
  return nil if xcargs.to_s.include?('-clonedSourcePackagesDirPath')

  workspace = ENV['WORKSPACE'].to_s
  workspace.empty? ? $IOS_SOURCE_PACKAGES_PATH : File.join("#{workspace}@spm-cache", 'SourcePackages')
end

def smf_is_using_old_build_system
  project_root = smf_workspace_dir

  return false if project_root.nil?

  case @platform
  when :flutter
    project_root = project_root + "/ios"
  else
    project_root = project_root
  end

  workspace_file = `cd #{project_root} && ls | grep -E "(.|\s)+\.xcworkspace"`.gsub("\n", "")

  if (workspace_file == "" || workspace_file == nil)
    return false
  end

  file_to_search = File.join(project_root, "#{workspace_file}/xcshareddata/WorkspaceSettings.xcsettings")

  return false if (File.exist?(file_to_search) == false)

  file_to_search_opened = File.open(file_to_search, "r")
  contents = file_to_search_opened.read

  regex = /<key>BuildSystemType<\/key>\n\t<string>Original<\/string>/

  return true if (contents.match(regex) != nil)

end

# The name of the newest valid match profile installed for this identifier, or nil.
#
# Matches "match <Type> <identifier>" exactly or followed by the timestamp the
# Developer Portal appends when the plain name is already taken. Expired profiles
# are skipped — an old one under the plain name can still be lying around and
# would otherwise win. Of the rest, the latest expiry wins and, among profiles
# tied on it, the latest creation: renewed profiles on one certificate all expire
# with it, and only the newest is the one match keeps in its repository.
def _smf_installed_match_profile_name(type_name, identifier, team_id)
  name_pattern = /\Amatch #{Regexp.escape(type_name)} #{Regexp.escape(identifier)}( \d+)?\z/
  directories = [
    File.expand_path('~/Library/Developer/Xcode/UserData/Provisioning Profiles'),
    File.expand_path('~/Library/MobileDevice/Provisioning Profiles')
  ]

  candidates = directories.flat_map { |dir| Dir.glob(File.join(dir, '*.mobileprovision')) }.filter_map do |path|
    xml = `security cms -D -i #{Shellwords.escape(path)} 2>/dev/null`
    next if xml.empty?

    profile = Plist.parse_xml(xml)
    next unless profile.is_a?(Hash) && profile['Name'].to_s.match?(name_pattern)
    next if team_id && !Array(profile['TeamIdentifier']).include?(team_id)
    next unless profile['ExpirationDate'] && profile['ExpirationDate'] > DateTime.now

    profile
  rescue StandardError => e
    UI.verbose("Skipping #{path}: #{e.message}")
    nil
  end

  candidates.max_by { |profile| [profile['ExpirationDate'], profile['CreationDate']] }&.fetch('Name')
end
