private_lane :smf_dependency_report do |options|
  build_variant = options[:build_variant]
  project_name = options[:meta_db_project_name]
  dependencyReport = nil
  begin
    case @platform
    when :android
      dependencyReport = _smf_dependency_report_android
    when :ios, :macos
      dependencyReport = _smf_dependency_report_cocoapods
      dependencyReport["project_type"] = "iOS"
    when :macos
      dependencyReport = _smf_dependency_report_cocoapods
      dependencyReport["project_type"] = "macOS"
    else
      UI.message("The platform \"#{@platform}\" does not support dependency reports")
    end
  rescue
    UI.message("Platform dependencies could not be reported")
  end

  unless dependencyReport.nil?
    dependencyReport["environment"] = build_variant
    dependencyReport["project"] = project_name
    _smf_send_dependency_report(dependencyReport)
  end
end

def _smf_dependency_report_android
  gradle(task: 'allLicenseReport')
  dependencies = []
  smf_get_file_paths("license*Report.json").each { |path|
    report = JSON.parse(File.read(path), :symbolize_names => false)
    report.each { |value|
      license = value['licenses'][0]['license'] unless value['licenses'].nil? || value['licenses'].empty?

      dependencies.append({
        'name' => value['dependency'].sub(":#{value['version']}", ""),
        'version' => value['version'],
        'license' => license
      })
    }
  }

  apiData = {
    "software_versions" => dependencies,
    "type" => "dependency",
    "package_manager" => "gradle",
    "project_type" => "Android"
  }
  apiData
end

def _smf_dependency_report_cocoapods

  podfile = YAML.load(File.read(smf_get_file_path("Podfile.lock")))

  dependencies = []
  podfile["DEPENDENCIES"].each { |value|

    dependency = value.match(/([0-9a-zA-Z_\/]*) \((.*)\)/)
    version = dependency[2]

    # parse tag from dependency versions like "from `https://github.com/getsentry/sentry-cocoa.git`, tag `3.13.1`"
    tagVersionMatch = version.match(/from \`.*\`, tag \`(.*)\`/)
    if tagVersionMatch
      version = tagVersionMatch[1]
    end

    # converts dependency version from "= 3.13.1" to "3.13.1"
    absoluteVersionMatch = version.match(/[^\d]*(\d.*)/)
    if absoluteVersionMatch
      version = absoluteVersionMatch[1]
    end

    dependencies.append({
        'name' => dependency[1],
        'version' => version
    })
  }

  apiData = {
    "software_versions" => dependencies,
    "type" => "dependency",
    "package_manager" => "cocoapods"
  }
  apiData
end

def _smf_send_dependency_report(report)
  uri = URI('https://metadb.solutions.smfhq.com/api/v1/software')

  https = Net::HTTP.new(uri.host,uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req.body = report.to_json
  auth = ENV[$SMF_METADB_API_CREDENTIALS].split(':')
  req.basic_auth auth[0], auth[1]

  res = https.request(req)

  UI.message("dependency data was reported:\n#{res.body}")
end
