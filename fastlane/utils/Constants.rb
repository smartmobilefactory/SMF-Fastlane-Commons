$METAJSON_TEMP_FOLDERNAME = '.MetaJSON-temp'

# Environmental variables keys
$SMF_CHANGELOG_ENV_HTML_KEY = 'SMF_CHANGELOG_HTML'
$SMF_CHANGELOG_EMAILS_ENV_KEY = 'SMF_CHANGELOG_EMAILS'
$SMF_GITHUB_TOKEN_ENV_KEY = 'GITHUB_TOKEN'
$SMF_HOCKEYAPP_API_TOKEN_ENV_KEY = 'HOCKEYAPP_API_TOKEN'
$SMF_APP_HOCKEY_ID_ENV_KEY = 'SMF_APP_HOCKEY_ID'
$SMF_APPCENTER_API_TOKEN_ENV_KEY = 'APPCENTER_API_TOKEN'
$SMF_HIPCHAT_API_TOKEN_ENV_KEY = 'HIPCHAT_API_TOKEN'
$SMF_ONE_SIGNAL_BASIC_AUTH_ENV_KEY = 'SMF_HOCKEYAPP_ONE_SIGNAL_BASIC_AUTH'
$SMF_SLACK_URL = 'SMF_SLACK_URL_IDENTIFIER'
$SMF_DID_RUN_UNIT_TESTS_ENV_KEY = 'SMF_DID_RUN_UNIT_TESTS'

$SMF_JENKINS_UI_TEST_USER_USERNAME = 'JENKINS_UI_TEST_USER_USERNAME'
$SMF_JENKINS_UI_TEST_USER_PASSWORD = 'JENKINS_UI_TEST_USER_PASSWORD'
$SMF_UI_TEST_REPORT_NAME_FOR_NOTIFICATIONS = 'SMF_UI_TEST_REPORT_NAME_FOR_NOTIFICATIONS'

$WORKSPACE_ENV_KEY = 'WORKSPACE'

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

# We host our own Sentry server so we need to supply the URL ourselves
$SENTRY_AUTH_TOKEN = 'SENTRY_API_ACCESS_TOKEN'

# match
$FASTLANE_MATCH_REPO_URL = 'git@github.com:smartmobilefactory/SMF-iOS-Fastlane-Match.git'
$SMF_FASTLANE_ITC_TEAM_ID_KEY = 'FASTLANE_ITC_TEAM_ID'

$SMF_PHRASE_APP_ACCESS_TOKEN_KEY = 'SMF_PHRASEAPP_ACCESS_TOKEN'
$SMF_PHRASE_APP_CUSTOM_TOKEN_KEY = 'CUSTOM_PHRASE_APP_TOKEN'
$SMF_PHRASE_APP_SCRIPTS_REPO_URL = 'git@github.com:smartmobilefactory/Phraseapp-CI.git'

$CHANGELOG_TEMP_FILE = 'temp_changelog.txt'
$CHANGELOG_TEMP_FILE_HTML = 'temp_changelog.html'

$POD_DEFAULT_VARIANTS = ['patch', 'minor', 'major', 'current', 'breaking', 'internal']
