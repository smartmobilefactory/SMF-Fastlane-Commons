#!/usr/bin/ruby
require 'net/https'
require 'uri'
require 'json'

def color_for_type(type)
  case type
  when 'success'
    '#4caf50' # green
  when 'warning'
    '#ffc107' # orange
  when 'message'
    '#2196f3' # blue
  when 'error'
    '#f44336' # red
  else
    '#9e9e9e' # gray
  end
end

def _smf_post_slack_request(message)
  header = {
    'Content-Type' => 'application/json; charset=utf-8',
    'Authorization' => "Bearer #{ENV[$SMF_SLACK_URL]}"
  }

  uri = URI('https://slack.com/api/chat.postMessage')
  request = Net::HTTP::Post.new(uri, header)
  request.body = message.to_json

  https_request = Net::HTTP.new(uri.host, uri.port).tap do |http|
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  response = https_request.request(request)
  response
end

def _smf_slack_message_body(data)
  text = data[:message]

  if (text.nil? or text == '')
    pretext = data[:pretext]
    # Remove emojis for a more minimal message content
    text = pretext.gsub(/:[a-z_]+:/, '').strip()
  end

  return text
end

def _smf_send_slack_message(data)
  # Build message
  message = {
    :icon_url => data[:icon_url],
    :channel => data[:channel],
    :username => data[:username],
    :attachments => [
      {
        :color => color_for_type(data[:type]),
        :pretext => data[:pretext],
        :text => _smf_slack_message_body(data),
        :fields => [],
        :footer => 'Jenkins CI Notifications',
        :footer_icon => data[:icon_url],
        :ts => Time.now.to_i
      }
    ]
  }

  # Add attachments
  data[:payload].each do |key, value|
    payload_json = {
      :title => key,
      :value => value,
      :short => false
    }

    message[:attachments][0][:fields].push(payload_json)
  end

  # POST request
  _smf_post_slack_request(message)
end
