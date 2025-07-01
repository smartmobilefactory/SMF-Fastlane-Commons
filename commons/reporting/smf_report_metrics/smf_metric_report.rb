private_lane :smf_report_metrics do |options|
  smf_report_depencencies(options)
  # OWASP reporting is disabled
  # smf_owasp_report(options)
  smf_meta_report(options)
end

private_lane :smf_meta_report do |options|
  begin
    case @platform
    when :ios, :macos, :apple, :ios_framework
      smf_meta_report_ios(options)
    when :android
      smf_meta_report_android(options)
    else
      UI.message("The platform \"#{@platform}\" does not support meta reports")
    end
  rescue Exception => ex
    UI.message("Meta report could not be performed: #{ex.message}")
    project_name = @smf_fastlane_config[:project][:project_name]
    smf_send_message(
      title: "#{project_name} smf_meta_report failed",
      message: "#{ex.message}, #{ex}",
      slack_channel: $SMF_CI_DIAGNOSTIC_CHANNEL
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
    project_name = @smf_fastlane_config[:project][:project_name]
    smf_send_message(
      title: "#{project_name} smf_owasp_report failed",
      message: "#{ex.message}, #{ex}",
      slack_channel: $SMF_CI_DIAGNOSTIC_CHANNEL
    )
  end
  # OWASP reporting functionality removed
end

private_lane :smf_report_depencencies do |options|
  UI.message("Dependency reporting has been disabled")
end

