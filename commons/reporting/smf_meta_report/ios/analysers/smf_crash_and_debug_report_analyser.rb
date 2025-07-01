
# Constants
PODFILE_LOCK_NAME = 'Podfile.lock'

# Pods to analyse
SENTRY_PODNAME = 'Sentry'
DEBUG_MENU_PODNAME = 'SMF-Debug-Menu'
QAKIT_PODNAME = 'QAKit'

# Helper
def _smf_podfile_path
  File.join(smf_workspace_dir, PODFILE_LOCK_NAME)
end

def _smf_make_regex_for_pod(name)
  /\s\s-\s#{name}\s\((?<version>.+)\)/
end

def _smf_analyse_pod_usage_for(name)
  podfile_content = File.read(_smf_podfile_path)
  regex = _smf_make_regex_for_pod(name)
  result = podfile_content.match(regex)

  unless result.nil?
    return result[:version]
  end

  return nil
end

# POD ANALYSIS


def smf_analyse_sentry_usage
  _smf_analyse_pod_usage_for(SENTRY_PODNAME)
end

def smf_analyse_qakit_usage
  _smf_analyse_pod_usage_for(QAKIT_PODNAME)
end

def smf_analyse_debug_menu_usage
  _smf_analyse_pod_usage_for(DEBUG_MENU_PODNAME)
end
