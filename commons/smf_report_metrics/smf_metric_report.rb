private_lane :smf_report_metrics do |options|
  smf_report_depencencies(options)
  smf_owasp_report(options)
end

private_lane :smf_owasp_report do |options|

  begin
    case @platform
    when :android
      report = smf_owasp_report_android
    else
      UI.message("The platform \"#{@platform}\" does not support owasp reports")
    end
  rescue Exception => ex
    UI.message("Platform dependencies could not be reported: #{ex.message}")
  end
  # TODO report owasp report to metadb
end

private_lane :smf_report_depencencies do |options|

  build_variant = options[:build_variant]
  project_name = options[:meta_db_project_name]
  dependencyReports = []

  prepare_api_data = ->(data) {
    data['environment'] = build_variant
    data['project'] = project_name
    data
  }

  begin
    case @platform
    when :android
      dependencyReports.push(prepare_api_data.call(smf_general_dependency_report_android))
      dependencyReports.push(prepare_api_data.call(smf_development_dependency_report_android))
      dependencyReports.push(prepare_api_data.call(smf_dependency_report_android))
    when :ios
      report = smf_dependency_report_cocoapods
      report['project_type'] = 'iOS'
      dependencyReports.push(prepare_api_data.call(report))
    when :macos
      report = smf_dependency_report_cocoapods
      report['project_type'] = 'macOS'
      dependencyReports.push(prepare_api_data.call(report))
    else
      UI.message("The platform \"#{@platform}\" does not support metric reports")
    end
  rescue Exception => ex
    UI.message("Platform dependencies could not be reported: #{ex.message}")
  end

  dependencyReports.each { |value|
    _smf_send_dependency_report(value)
  }
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

lane :check_owasp do |options|
    report = []
    owasp_report = JSON.parse(File.read(smf_get_file_path('dependency-check-report.json')), :symbolize_names => false)
    owasp_report['dependencies'].each { |dependency|
        if !dependency['vulnerabilities'].empty?
            vulnerabilityNames = dependency['vulnerabilities'].map { |it| it['name'] }
            dependency['packages'].each { |package|
                # example: pkg:maven/com.squareup.okhttp3/okhttp@3.10.0",
                packageIdMatch = package['id'].match(/pkg:maven\/(.*)@(.*)/)
                if packageIdMatch
                    report.append({
                        'id' => packageIdMatch[1].gsub('/', ':'),
                        'vulnerabilities' => vulnerabilityNames
                    })
                end
            }
        end
    }
    UI.message("REPORT: #{report.to_json}")
    report
end

