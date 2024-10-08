
def _smf_should_skip_notifications_for_branch(project_name)
  branch = smf_workspace_dir_git_branch

  if branch.match(/^master$/) # iOS (A-Team)
    return false
  end

  if branch.match(/^\d+[\d\.]*\/master$/) # iOS (Strato-Team)
    return false
  end

  if branch.match(/^dev$/) # Android
    return false
  end

  if branch.match(/^kmpp$/) # Android (Eismann - temporary)
    return false
  end

  if project_name.downcase.include?('playground') && !branch.match(/^PR-.*$/)
    return false
  end

  return true
end


def _smf_should_skip_main_channel_slack_notifications
  return true if ENV[$SEND_ERRORS_TO_CI_SLACK_CHANNEL_ONLY_KEY]
end

desc 'Sending a message to the given Slack channel'
private_lane :smf_send_message do |options|

  title = "*#{options[:title]}*"
  message = !options[:message].nil? ? options[:message] : ''
  content = message.length < 4000 ? message : "#{message[0..4000]}... (maximum length reached)"

  case @platform
  when :ios, :ios_framework, :macos, :apple
    ci_error_log = smf_ci_ios_error_log
  when :android
    ci_error_log = $SMF_CI_ANDROID_ERROR_LOG.to_s
  when :flutter
    ci_error_log = $SMF_CI_FLUTTER_ERROR_LOG.to_s
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

  slack_channel = !options[:slack_channel].nil? ? options[:slack_channel] : ci_error_log

  project_name = !ENV['PROJECT_NAME'].nil? ? ENV['PROJECT_NAME'] : @smf_fastlane_config[:project][:project_name]
  type = !options[:type].nil? ? options[:type].to_s : 'warning'
  build_url = !options[:build_url].nil? ? options[:build_url] : ENV['BUILD_URL']
  exception = options[:exception]
  additional_html_entries = !options[:additional_html_entries].nil? ? options[:additional_html_entries] : []
  fail_build_job_on_error = (!options[:fail_build_job_on_error].nil? ? options[:fail_build_job_on_error] : false)
  icon_url = 'https://avatars2.githubusercontent.com/u/1090089'

  # Log the exceptions to find out if there is useful information which can be added to the message
  UI.message("exception.inspect: #{exception.inspect}")
  UI.message("exception.cause: #{exception.cause}") if exception.respond_to?(:cause)
  UI.message("exception.exception: #{exception.exception}") if exception.respond_to?(:exception)
  UI.message("exception.backtrace: #{exception.backtrace}") if exception.respond_to?(:backtrace)
  UI.message("exception.backtrace_locations: #{exception.backtrace_locations}") if exception.respond_to?(:backtrace_locations)
  UI.message("exception.error_info: #{exception.error_info}") if exception.respond_to?(:error_info)
  slack_channel = URI.decode_www_form_component(slack_channel) == slack_channel ? URI.encode_www_form_component(slack_channel) : slack_channel

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

  unless _smf_should_skip_main_channel_slack_notifications || (slack_channel.eql? ci_error_log)
    UI.message("Sending message \"#{content}\" to room \"#{slack_channel}\"")
  end

  if _smf_should_skip_notifications_for_branch(project_name)
    UI.message("[WARNING]: skip slack notifications from development branches")

  elsif slack_channel && (slack_channel.include? '/') == false

    payload = {
      'Build Job' => build_url,
      'Build Result' => type,
      'Git Branch' => smf_workspace_dir_git_branch
    }

    payload['Notarization Log'] = ENV['FL_NOTARIZE_LOG_FILE_URL'] if @platform == :macos and !ENV['FL_NOTARIZE_LOG_FILE_URL'].nil?

    # Send failure messages also to CI to notice them so that we can see if they can be improved
    if type == 'error' && !(slack_channel.eql? ci_error_log)
      _smf_send_slack_message(
        icon_url: icon_url,
        title: title,
        message: content,
        channel: project_name.downcase.include?('playground') ? 'ci-development' : ci_error_log,
        username: "#{project_name} CI",
        type: type,
        payload: payload
      )
    end

    if _smf_should_skip_main_channel_slack_notifications
      UI.message("[INFO]: Skipping slack notifications for main channel")
    else
      begin
        _smf_send_slack_message(
          icon_url: icon_url,
          title: title,
          message: content,
          channel: slack_channel,
          username: "#{project_name} CI",
          type: type,
          payload: payload
        )
      rescue => exception
        UI.important("Failed to send message to #{slack_channel} Slack room. Exception: #{exception}")
        raise exception if fail_build_job_on_error
      end
    end

  elsif slack_channel
    UI.error("Didn't send message as \"slack_channel\" contains \"/\"")
  else
    UI.message("Didn't send message as \"slack_channel\" is nil")
  end
end
