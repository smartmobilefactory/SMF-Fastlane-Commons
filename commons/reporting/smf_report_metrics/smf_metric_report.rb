private_lane :smf_report_metrics do |options|
  smf_report_depencencies(options)
  # Disabled for now as the owasp data are not sent to metaDB.
  # smf_owasp_report(options)
  smf_meta_report(options)
end

private_lane :smf_meta_report do |options|
  begin
    case @platform
    when :ios, :macos, :apple, :ios_framework
      smf_meta_report_ios(options)
    else
      UI.message("The platform \"#{@platform}\" does not support meta reports")
    end
  rescue Exception => ex
    UI.message("Meta report could not be performed: #{ex.message}")
    project_name = @smf_fastlane_config[:project][:project_name]
    smf_send_diagnostic_message(
      title: "#{project_name} smf_meta_report failed",
      message: "#{ex.message}, #{ex}"
    )
  end
end

private_lane :smf_owasp_report do |options|
  begin
    case @platform
    when :android
      report = smf_owasp_report_android
    when :ios, :macos, :apple
      report = smf_owsap_report_cocoapods
    else
      UI.message("The platform \"#{@platform}\" does not support owasp reports")
    end
    UI.message("OWASP REPORT: #{report.to_json}")
  rescue Exception => ex
    UI.message("Platform dependencies could not be reported: #{ex.message}")
    project_name = options[:smf_get_meta_db_project_name]
    smf_send_message(
      title: "#{project_name} smf_owasp_report failed",
      message: "#{ex.message}, #{ex}",
      slack_channel: 'metadb-error-log'
    )
  end
  # TODO report owasp report to metadb
end

private_lane :smf_report_depencencies do |options|

  build_variant = options[:build_variant]
  project_name = options[:smf_get_meta_db_project_name]
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
    when :apple
      report = smf_dependency_report_cocoapods
      report['project_type'] = smf_is_catalyst_mac_build(build_variant) ? 'macOS' : 'iOS'
      dependencyReports.push(prepare_api_data.call(report))
    else
      UI.message("The platform \"#{@platform}\" does not support metric reports")
    end
  rescue Exception => ex
    UI.message("Platform dependencies could not be reported: #{ex.message}")
    # smf_send_message(
    #   title: "#{project_name} report dependencies failed",
    #   message: "#{ex.message}, #{ex}",
    #   slack_channel: 'metadb-error-log'
    # )
  end

  dependencyReports.each { |value|
    _smf_send_dependency_report(value, project_name)
  }
end

def _smf_send_dependency_report(report, project_name)
  UI.message("report data:\n#{report.to_json}")
  uri = URI('https://metadb.solutions.smfhq.com/api/v1/software')

  https = Net::HTTP.new(uri.host,uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req.body = report.to_json
  auth = ENV[$SMF_METADB_API_CREDENTIALS].split(':')
  req.basic_auth auth[0], auth[1]

  res = https.request(req)

  UI.message("dependency data were reported:\n#{res.body}")
  smf_send_message(
    title: "#{project_name} dependency data were reported to metaDB !!",
    message: "Debug notification to check whether the metaDB integration actually works... or not.",
    slack_channel: 'metadb-success-log'
  )
end
