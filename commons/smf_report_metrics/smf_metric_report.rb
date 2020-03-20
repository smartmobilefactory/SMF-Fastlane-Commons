private_lane :smf_report_metrics do |options|
  smf_report_depencencies(options)
  smf_owasp_report(options)
end

private_lane :smf_owasp_report do |options|
  project_name = options[:meta_db_project_name]
  begin
    case @platform
    when :android
      report = smf_owasp_report_android
    when :ios, :macos
      report = smf_owsap_report_cocoapods
    else
      UI.message("The platform \"#{@platform}\" does not support owasp reports")
    end
    UI.message("OWASP REPORT: #{report.to_json}")
  rescue Exception => ex
    UI.message("Platform dependencies could not be reported: #{ex.message}")
    smf_send_diagnostic_message(
      title: "#{project_name} smf_owasp_report failed",
      message: "#{ex.message}, #{ex}"
    )
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
    smf_send_diagnostic_message(
      title: "#{project_name} report dependencies failed",
      message: "#{ex.message}, #{ex}"
    )
  end

  dependencyReports.each { |value|
    _smf_send_dependency_report(value)
  }
end

def _smf_send_dependency_report(report)
  UI.message("repot data:\n#{report.to_json}")
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
