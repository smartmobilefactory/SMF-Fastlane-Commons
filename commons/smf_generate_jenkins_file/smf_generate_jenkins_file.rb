require 'json'

# Local Constants
BUILD_VARIANTS_PATTERN = "__BUILD_VARIANTS__"
POD_EXAMPLE_VARIANTS_PATTERN = "__EXAMPLE_VARIANTS__"
FALLBACK_TEMPLATE_CREDENTIAL_KEY = "PIPELINE_TEMPLATE_CREDENTIAL"
CUSTOM_IOS_CREDENTIALS = [
    "__CUSTOM_PHRASE_APP_TOKEN__",
    "__CUSTOM_SPARKLE_PRIVATE_SSH_KEY__",
    "__CUSTOM_SPARKLE_SIGNING_KEY__"
]

# iOS/macOS Templates
IOS_APP_TEMPLATE_JENKINS_FILE = 'Jenkinsfile_iOS.template'
POD_TEMPLATE_JENKINS_FILE = 'Jenkinsfile_iOS_Framework.template'
MACOS_TEMPLATE_JENKINS_FILE = 'Jenkinsfile_macOS.template'

# Android Templates
ANDROID_APP_TEMPLATE_JENKINS_FILE = 'Jenkinsfile_Android.template'
ANDROID_FRAMEWORK_TEMPLATE_JENKINS_FILE = 'Jenkinsfile_Android_Framework.template'

# Flutter Template
FLUTTER_APP_TEMPLATE_JENKINS_FILE = 'Jenkinsfile_Flutter.template'

private_lane :smf_generate_jenkins_file do |options|

  custom_jenkinsfile_template = options[:custom_jenkinsfile_template]
  custom_jenkinsfile_path = options[:custom_jenkinsfile_path]
  remove_multibuild_variants = options[:remove_multibuild_variants].nil? ? false : options[:remove_multibuild_variants]

  jenkins_file_template_path = custom_jenkinsfile_template.nil? ? _smf_jenkins_file_template_path : custom_jenkinsfile_template
  jenkinsFileData = File.read(jenkins_file_template_path)
  possible_build_variants = remove_multibuild_variants ? @smf_fastlane_config[:build_variants].keys.map(&:to_s) : _smf_possible_build_variants
  jenkinsfile_path = custom_jenkinsfile_path.nil? ? "#{smf_workspace_dir}/Jenkinsfile" : custom_jenkinsfile_path

  UI.message("Generating Jenkinsfile with template at: #{jenkins_file_template_path}")

  if @platform == :ios_framework
    possible_build_variants = @smf_fastlane_config[:build_variants].select { |variant_key, variant_value|
      variant_value[:podspec_path] == nil && variant_value[:pods_specs_repo] == nil
    }.keys.map(&:to_s)

    possible_build_variants.push(*$POD_DEFAULT_VARIANTS)
  end

  jenkinsFileData = jenkinsFileData.gsub("#{BUILD_VARIANTS_PATTERN}", JSON.dump(possible_build_variants))

  jenkinsFileData = _smf_insert_custom_credentials(jenkinsFileData) unless @platform == :macos

  File.write(jenkinsfile_path, jenkinsFileData)
end

def _smf_jenkins_file_template_path
  path = nil
  case @platform
  when :ios
    path = "#{@fastlane_commons_dir_path}/commons/smf_generate_jenkins_file/#{IOS_APP_TEMPLATE_JENKINS_FILE}"
  when :android
    if @smf_fastlane_config[:project][:type] == 'framework'
      path = "#{@fastlane_commons_dir_path}/commons/smf_generate_jenkins_file/#{ANDROID_FRAMEWORK_TEMPLATE_JENKINS_FILE}"
    else
      path = "#{@fastlane_commons_dir_path}/commons/smf_generate_jenkins_file/#{ANDROID_APP_TEMPLATE_JENKINS_FILE}"
    end
  when :flutter
    path = "#{@fastlane_commons_dir_path}/commons/smf_generate_jenkins_file/#{FLUTTER_APP_TEMPLATE_JENKINS_FILE}"
  when :ios_framework
    path = "#{@fastlane_commons_dir_path}/commons/smf_generate_jenkins_file/#{POD_TEMPLATE_JENKINS_FILE}"
  when :macos
    path = "#{@fastlane_commons_dir_path}/commons/smf_generate_jenkins_file/#{MACOS_TEMPLATE_JENKINS_FILE}"
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

  path
end

def _smf_possible_build_variants
  build_variants = @smf_fastlane_config[:build_variants].keys.map(&:to_s)

  ['Live', 'Beta', 'Alpha'].each do |kind|
    kind_variants = build_variants.select do |variant|
      variant.downcase.include? kind.downcase
    end

    build_variants.insert(0, kind) if kind_variants.length > 1
  end

  build_variants
end

def _smf_insert_custom_credentials(jenkinsFile)
  jenkinsFileData = jenkinsFile
  case @platform
  when :ios, :macos
    for custom_credential in CUSTOM_IOS_CREDENTIALS
      if @smf_fastlane_config[:project][:custom_credentials] && @smf_fastlane_config[:project][:custom_credentials][custom_credential.to_sym]
        custom_credential_key = @smf_fastlane_config[:project][:custom_credentials][custom_credential.to_sym]
        jenkinsFileData = jenkinsFileData.gsub(custom_credential, custom_credential_key)
      else
        jenkinsFileData = jenkinsFileData.gsub(custom_credential, FALLBACK_TEMPLATE_CREDENTIAL_KEY)
      end
    end

  when :android
  when :flutter
    UI.message('Inserting custom credentials for flutter is not implemented yet')
  when :ios_framework
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

  jenkinsFileData
end
