private_lane :smf_report_metrics do |options|

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
      dependencyReport.push(prepare_api_data.call(smf_general_dependency_report_android))
      dependencyReport.push(prepare_api_data.call(smf_development_dependency_report_android))
      dependencyReport.push(prepare_api_data.call(smf_dependency_report_android))
    when :ios
      report = smf_dependency_report_cocoapods
      report['project_type'] = 'iOS'
      dependencyReport.push(prepare_api_data.call(report))
    when :macos
      report = smf_dependency_report_cocoapods
      report['project_type'] = 'macOS'
      dependencyReport.push(prepare_api_data.call(report))
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
