desc 'Sending a message to the given Slack channel'

def _smf_should_skip_notifications_for_branch
  branch = smf_workspace_dir_git_branch

  if branch.match(/^master$/) # iOS (A-Team)
    return false
  end

  if branch.match(/^\d+\.?\d*\/master$/) # iOS (Strato-Team)
    return false
  end

  if branch.match(/^dev$/) # Android
    return false
  end

  if branch.match(/^kmpp$/) # Android (Eismann - temporary)
    return false
  end

  return true
end

private_lane :smf_send_message do |options|

  slack_workspace_url = "https://hooks.slack.com/services/#{ENV[$SMF_SLACK_URL]}"
  title = "*#{options[:title]}*"
  message = !options[:message].nil? ? options[:message] : ''
  content = message.length < 4000 ? message : "#{message[0..4000]}... (maximum length reached)"

  case @platform
  when :ios, :ios_framework, :macos, :apple
    ci_error_log = smf_ci_ios_error_log
  when :android
    ci_error_log = ci_android_error_log
  when :flutter
    ci_error_log = ci_flutter_error_log
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

  slack_channel = !options[:slack_channel].nil? ? options[:slack_channel] : ci_error_log

  project_name = !ENV['PROJECT_NAME'].nil? ? ENV['PROJECT_NAME'] : @smf_fastlane_config[:project][:project_name]
  type = !options[:type].nil? ? options[:type].to_s : 'warning'
  success = type == 'success' || type == 'message'
  build_url = !options[:build_url].nil? ? options[:build_url] : ENV['BUILD_URL']
  exception = options[:exception]
  additional_html_entries = !options[:additional_html_entries].nil? ? options[:additional_html_entries] : []
  fail_build_job_on_error = (!options[:fail_build_job_on_error].nil? ? options[:additional_html_entries] : false)
  attachment_path = options[:attachment_path]
  icon_url = 'https://avatars2.githubusercontent.com/u/1090089'

  # Log the exceptions to find out if there is useful information which can be added to the message
  UI.message("exception.inspect: #{exception.inspect}")
  UI.message("exception.cause: #{exception.cause}") if exception.respond_to?(:cause)
  UI.message("exception.exception: #{exception.exception}") if exception.respond_to?(:exception)
  UI.message("exception.backtrace: #{exception.backtrace}") if exception.respond_to?(:backtrace)
  UI.message("exception.backtrace_locations: #{exception.backtrace_locations}") if exception.respond_to?(:backtrace_locations)
  UI.message("exception.error_info: #{exception.error_info}") if exception.respond_to?(:error_info)
  slack_channel = URI.unescape(slack_channel) == slack_channel ? URI.escape(slack_channel) : slack_channel

  unless exception.nil?
    error_info = exception.respond_to?(:error_info) ? exception.error_info : nil
    error_info = exception.exception if error_info.nil?
    unless error_info.nil?
      UI.message("Found error_info: #{error_info.to_s}")
      UI.message("Adding error_info: #{error_info.to_s}")
      content << error_info.to_s
      if content.length > 4000
        content = "#{content[0..4000]}... (maximum length reached)"
      end
    end
  end

  additional_html_entries&.each do |entry|
    UI.message("Adding additional_html_entry: #{entry}")
    content << entry.to_s
  end

  UI.message("Sending message \"#{content}\" to room \"#{slack_channel}\"")

  if _smf_should_skip_notifications_for_branch
    UI.message("[WARNING]: skip slack notifications from development branches")

  elsif slack_channel && (slack_channel.include? '/') == false

    payload = {
      'Build Job' => build_url,
      'Build Type' => type,
    }

    payload['Notarization Log'] = ENV['FL_NOTARIZE_LOG_FILE_URL'] if @platform == :mac and !ENV['FL_NOTARIZE_LOG_FILE_URL'].nil?

    # Send failure messages also to CI to notice them so that we can see if they can be improved
    begin
      if type == 'error' && !(slack_channel.eql? ci_error_log)
        slack(
            slack_url: slack_workspace_url,
            icon_url: icon_url,
            pretext: title,
            message: content,
            channel: ci_error_log,
            username: "#{project_name} CI",
            success: success,
            payload: payload,
            default_payloads: [:git_branch],
        )
      end
    rescue => exception
      UI.important("Failed to send error message to #{ci_error_log} Slack room. Exception: #{exception}")
    end

    begin
      if !attachment_path.nil?
        slack(
            slack_url: slack_workspace_url,
            icon_url: icon_url,
            pretext: title,
            message: content,
            channel: slack_channel,
            username: "#{project_name} CI",
            success: success,
            payload: payload,
            default_payloads: [:git_branch],
            attachment_properties: {
                fields: [
                    {
                        title: 'Attachment',
                        value: attachment_path.to_s
                    }
                ]
            }
        )
      else
        slack(
            slack_url: slack_workspace_url,
            icon_url: icon_url,
            pretext: title,
            message: content,
            channel: slack_channel,
            username: "#{project_name} CI",
            success: success,
            payload: payload,
            default_payloads: [:git_branch],
        )
      end
    rescue => exception
      UI.important("Failed to send error message to #{slack_channel} Slack room. Exception: #{exception}")
      raise exception if fail_build_job_on_error
    end

  elsif slack_channel
    UI.error("Didn't send message as \"slack_channel\" contains \"/\"")
  else
    UI.message("Didn't send message as \"slack_channel\" is nil")
  end

end

