desc "Handle the exception"
private_lane :smf_handle_exception do |options|
  UI.important("Handling the build job exception")

  message = options[:message]
  exception = options[:exception]
  build_variant = options[:build_variant]

  smf_send_default_build_fail_notification(build_variant: build_variant, message: message, exception: exception)

end
