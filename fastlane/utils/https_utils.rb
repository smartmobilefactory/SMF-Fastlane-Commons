# Function for basic https requests
def smf_https_get_request(url, auth_type, credentials)
  uri = URI(url)

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Get.new(uri)
  if auth_type == :basic
    credentials = credentials.split(':')
    req.basic_auth(credentials[0], credentials[1])
  elsif auth_type == :token
    req['Authorization'] = "token #{credentials}"
  end

  res = https.request(req)

  return nil if res.code != '200'

  JSON.parse(res.body, {symbolize_names: true})
end

# Function for basic https posts
def smf_https_post_request(url, auth_type, credentials, body)
  uri = URI(url)

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri)
  req['Content-Type'] = 'application/json'

  if auth_type == :basic
    credentials = credentials.split(':')
    req.basic_auth(credentials[0], credentials[1])
  elsif auth_type == :token
    req['Authorization'] = "token #{credentials}"
  end

  req.body = body.to_json

  res = https.request(req)

  case res
  when Net::HTTPSuccess
    return nil
  else
    return "POST: #{res.uri}\nSTATUS: #{res.code}\nMESSAGE: #{res.msg}"
  end

end

