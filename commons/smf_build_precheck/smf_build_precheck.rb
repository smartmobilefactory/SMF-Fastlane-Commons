private_lane :smf_build_precheck do |options|

  upload_itc = options[:upload_itc]
  itc_apple_id = options[:itc_apple_id]

  case @platform
  when :ios, :flutter
    perform_build_precheck_ios(upload_itc, itc_apple_id)
  else
    UI.message('Build Precheck: Nothing reportable found')
  end
end

def perform_build_precheck_ios(upload_itc, itc_apple_id)

  if upload_itc == true && itc_apple_id.nil?
    message = 'itc_apple_id not set in Config.json. Please Read: https://smartmobilefactory.atlassian.net/wiki/spaces/SMFIOS/pages/669646876/Missing+itc+apple+id '

    smf_send_message(
        title: 'Build Precheck Error',
        message: message,
        type: 'error'
    )

    raise message
  else
    UI.message('Build Precheck: Nothing reportable found')
  end
end
