#!/usr/bin/ruby
require 'net/https'
require 'uri'
require 'json'

def https(uri)
  Net::HTTP.new(uri.host, uri.port).tap do |http|
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

def _smf_send_slack_message(data)

  header = {
    'Content-Type' => 'application/json; charset=utf-8',
    'Authorization' => "Bearer #{ENV[$SMF_SLACK_URL]}"
  }

  message = {
    :icon_url => data[:icon_url],
    :channel => data[:channel],
    :username => data[:username],
    :attachments => [
      {
        :color => (data[:success] == true ? "#36a64f" : "#a30101" ),
        :pretext => data[:pretext],
        :text => data[:message],
        :fields => [],
        :footer => 'Jenkins CI Notifications',
        :footer_icon => data[:icon_url],
        :ts => Time.now.to_i
      }
    ]
  }

  data[:payload].each do |key, value|
    payload_json = {
      :title => key,
      :value => value,
      :short => false
    }

    message[:attachments][0][:fields].append(payload_json)
  end

  uri = URI('https://slack.com/api/chat.postMessage')
  request = Net::HTTP::Post.new(uri, header)
  request.body = message.to_json
  response = https(uri).request(request)
end
