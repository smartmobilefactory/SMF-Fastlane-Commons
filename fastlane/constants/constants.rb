# Environmental variables keys
$SMF_GITHUB_TOKEN_ENV_KEY = 'GITHUB_TOKEN'
$SMF_SLACK_URL = 'SMF_SLACK_URL_IDENTIFIER'
$JIRA_DEV_ACCESS_CREDENTIALS = 'JIRA_TOKEN_FASTLANE_ACCESS'
$SENTRY_AUTH_TOKEN = 'SENTRY_API_ACCESS_TOKEN'
$DANGER_GITHUB_TOKEN_KEY = 'DANGER_GITHUB_API_TOKEN'

# External URLs
$JIRA_BASE_URL = 'https://sosimple.atlassian.net'
$FASTLANE_MATCH_REPO_URL = 'git@github.com:smartmobilefactory/SMF-iOS-Fastlane-Match.git'

# Keychain
$SMF_IS_KEYCHAIN_ENABLED = 'SMF_IS_KEYCHAIN_ENABLED'
$KEYCHAIN_LOGIN_ENV_KEY = 'LOGIN'
$KEYCHAIN_JENKINS_ENV_KEY = 'JENKINS'

# Path to xcode versions, used for xcode_select and ensure_xcode_version in combination with the projects xcode version
$XCODE_EXECUTABLE_PATH_PREFIX = '/Applications/Xcode-'
$XCODE_EXECUTABLE_PATH_POSTFIX = '.app'
$DEVELOPMENT_DIRECTORY_KEY = 'DEVELOPMENT_DIR'

# Default Slack channel to send logs to
$SMF_CI_IOS_ERROR_LOG = 'ci-ios-error-log'
$SMF_CI_ANDROID_ERROR_LOG = 'ci-android-error-log'
$SMF_CI_FLUTTER_ERROR_LOG = 'ci-flutter-error-log'
$SMF_CI_DIAGNOSTIC_CHANNEL = 'ci-diagnostic-messages'

# PhraseApp
$SMF_PHRASE_APP_ACCESS_TOKEN_KEY = 'PHRASEAPP_API_ACCESS_TOKEN'
$SMF_PHRASE_APP_SCRIPTS_REPO_URL = 'git@github.com:smartmobilefactory/Phraseapp-CI.git'

# Changelog
$CHANGELOG_TEMP_FILE = 'temp_changelog.txt'
$CHANGELOG_TEMP_FILE_HTML = 'temp_changelog.html'
$CHANGELOG_TEMP_FILE_SLACK_MARKDOWN = 'temp_changelog_slack_markdown.text'
$TICKET_TAGS_TEMP_FILE = 'temp_ticket_tags.text'

# Build Options
$POD_DEFAULT_VARIANTS = ['patch', 'minor', 'major', 'current', 'breaking', 'internal']
$CATALYST_MAC_BUILD_VARIANT_PREFIX = 'macOS_'

$IOS_BUILD_OUTPUT_DIR = 'build'
$IOS_ARCHIVE_PATH = File.join($IOS_BUILD_OUTPUT_DIR, '/')
$IOS_DERIVED_DATA_PATH = File.join($IOS_BUILD_OUTPUT_DIR, 'derivedData/')
$IOS_ARCHIVE_BUILD_LOGS_DIRECTORY =  File.join($IOS_BUILD_OUTPUT_DIR, 'ArchiveBuildLogs/')
$IOS_UNIT_TESTS_BUILD_LOGS_DIRECTORY =  File.join($IOS_BUILD_OUTPUT_DIR, 'UnitTestsBuildLogs/')
$XCRESULT_DIR = File.join($IOS_DERIVED_DATA_PATH, 'Logs/Test')
$IOS_RESULT_BUNDLE_PATH = File.join($IOS_BUILD_OUTPUT_DIR, 'reports/bundleResults.xcresult')

$PODSPEC_REPO_SOURCES = ['git@github.com:smartmobilefactory/SMF-CocoaPods-Specs', 'https://github.com/CocoaPods/Specs']

### Reporting ###
# Google Sheets reporting has been disabled

# If set, error slack messages to the projects main slack channel are omitted
$SEND_ERRORS_TO_CI_SLACK_CHANNEL_ONLY_KEY = 'SEND_ERRORS_TO_CI_SLACK_CHANNEL_ONLY'

### Config.json Keys ###

# Deprecated files/folders in repository
$CONFIG_DEPRECATED_FILES_FOLDERS_COMMONS = ['.MetaJSON', '.codebeatignore', '.codebeatsettings', '.codeclimate.yml', 'smf.properties']
$CONFIG_DEPRECATED_FILES_FOLDERS_IOS = []
$CONFIG_DEPRECATED_FILES_FOLDERS_ANDROID = []
$CONFIG_DEPRECATED_FILES_FOLDERS_FLUTTER = []

# Required Config.json/project keys
$CONFIG_REQUIRED_PROJECT_KEYS_COMMONS = ['slack_channel', 'project_name']
$CONFIG_REQUIRED_PROJECT_KEYS_IOS = ['xcode_version']
$CONFIG_REQUIRED_PROJECT_KEYS_ANDROID = []
$CONFIG_REQUIRED_PROJECT_KEYS_FLUTTER = ['xcode_version']

# Optional Config.json/project keys
$CONFIG_OPTIONAL_PROJECT_KEYS_COMMONS = ['sentry_org_slug', 'sentry_project_slug']
$CONFIG_OPTIONAL_PROJECT_KEYS_IOS = ['custom_credentials', 'dmg_template_path', 'skip_build_nr_update_in_plists', 'skip_thread_sanitizer_for_unit_tests', 'use_custom_jenkinsfile']
$CONFIG_OPTIONAL_PROJECT_KEYS_ANDROID = []
$CONFIG_OPTIONAL_PROJECT_KEYS_FLUTTER = []

# Deprecated Config.json/build_variants
$CONFIG_DEPRECATED_BUILD_VARIANT_KEYS_IOS = ['pr.archive_ipa']
$CONFIG_DEPRECATED_BUILD_VARIANT_KEYS_ANDROID = []
$CONFIG_DEPRECATED_BUILD_VARIANT_KEYS_FLUTTER = []
