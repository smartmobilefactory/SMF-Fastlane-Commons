desc "Handle the exception"
private_lane :smf_handle_exception do |options|
  UI.important("Handling the build job exception")

  message = options[:message]
  exception = options[:exception]
  name = options[:name]

  smf_send_default_build_fail_notification(name: name, message: message, exception: exception)

end
