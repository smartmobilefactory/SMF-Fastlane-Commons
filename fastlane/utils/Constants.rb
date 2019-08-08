$METAJSON_TEMP_FOLDERNAME = ".MetaJSON-temp"

# Environmental variables keys
$SMF_CHANGELOG_ENV_KEY = "SMF_CHANGELOG"
$SMF_CHANGELOG_ENV_HTML_KEY = "SMF_CHANGELOG_HTML"
$SMF_CHANGELOG_EMAILS_ENV_KEY = "SMF_CHANGELOG_EMAILS"
$SMF_GITHUB_TOKEN_ENV_KEY = "GITHUB_TOKEN"
$SMF_HOCKEYAPP_API_TOKEN_ENV_KEY = "HOCKEYAPP_API_TOKEN"
$SMF_APP_HOCKEY_ID_ENV_KEY = "SMF_APP_HOCKEY_ID"
$SMF_HIPCHAT_API_TOKEN_ENV_KEY = "HIPCHAT_API_TOKEN"
$SMF_ONE_SIGNAL_BASIC_AUTH_ENV_KEY = "SMF_HOCKEYAPP_ONE_SIGNAL_BASIC_AUTH"
$SMF_SHOULD_BUILD_NUMBER_BE_INCREMENTED_ENV_KEY = "SHOULD_BUILD_NUMBER_BE_INCREMENTED"
$SMF_DID_RUN_UNIT_TESTS_ENV_KEY = "SMF_DID_RUN_UNIT_TESTS"
$FASTLANE_PLATFORM_NAME_ENV_KEY = "FASTLANE_PLATFORM_NAME"
$SMF_SHOULD_REVERT_BUILD_NUMBER = "SHOULD_REVERT_BUILD_NUMBER"
$SMF_PREVIOUS_BUILD_NUMBER = "PREVIOUS_BUILD_NUMBER"

$SMF_SIMULATOR_RELEASE_APP_ZIP_FILENAME = "SimulatorBuildRelease.zip"
$SMF_DEVICE_RELEASE_APP_ZIP_FILENAME = "DeviceBuildRelease.zip"
$SMF_JENKINS_UI_TEST_USER_USERNAME = "JENKINS_UI_TEST_USER_USERNAME"
$SMF_JENKINS_UI_TEST_USER_PASSWORD = "JENKINS_UI_TEST_USER_PASSWORD"
$SMF_UI_TEST_REPORT_NAME_FOR_NOTIFICATIONS = "SMF_UI_TEST_REPORT_NAME_FOR_NOTIFICATIONS"

$WORKSPACE_ENV_KEY = "WORKSPACE"

$SMF_IS_SLACK_ENABLED = "SMF_IS_SLACK_ENABLED"
$SMF_IS_KEYCHAIN_ENABLED = "SMF_IS_KEYCHAIN_ENABLED"

# Path to xcode versions, used for xcode_select and ensure_xcode_version in combination with the projects xcode version
$XCODE_EXECUTABLE_PATH_PREFIX = "/Applications/Xcode-"
$XCODE_EXECUTABLE_PATH_POSTFIX = ".app"
$DEVELOPMENT_DIRECTORY_KEY = "DEVELOPMENT_DIR"

# Default Slack channel to send logs to
$SMF_CI_IOS_ERROR_LOG = "ci-ios-error-log"

# We host our own Sentry server so we need to supply the URL ourselves
$SENTRY_URL = "https://sentry.solutions.smfhq.com/"
$SENTRY_AUTH_TOKEN = ENV["SENTRY_API_ACCESS_TOKEN"]

# match
$FASTLANE_MATCH_REPO_URL = "git@github.com:smartmobilefactory/SMF-iOS-Fastlane-Match.git"