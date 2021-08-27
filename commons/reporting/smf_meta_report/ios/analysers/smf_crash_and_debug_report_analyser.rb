
# Constants
PODFILE_LOCK_NAME = 'Podfile.lock'
APPCENTER_CRASHES_REGEX = /\s\s-\sAppCenter\/Crashes\s\((?<version>.+)\):/

# Helper
def _smf_podfile_path
  File.join(smf_workspace_dir, PODFILE_LOCK_NAME)
end

# Checks the podfile.lock for the appcenter crashes pod
# and returns the version if its found
def smf_analyse_appcenter_crash_report_usage
  podfile_content = File.read(_smf_podfile_path)
  result = podfile_content.match(APPCENTER_CRASHES_REGEX)

  unless result.nil?
    return result[:version]
  end

  return nil
end
