desc "Handle the exception"
private_lane :smf_handle_exception do |options|
  UI.important("Handling the build job exception")

  message = options[:message]
  exception = options[:exception]
  build_variant = options[:build_variant]

  case @platform
  when :ios
    apps_hockey_id = ENV[$SMF_APP_HOCKEY_ID_ENV_KEY]
    unless apps_hockey_id.nil?
      begin
        smf_delete_uploaded_hockey_entry(
            apps_hockey_id: apps_hockey_id
        )
        UI.important("The app version which was uploaded to HockeyApp was removed as something else in the build job failed!")
      rescue
        UI.message("The app version which was uploaded to HockeyApp wasn't removed. This is fine if it wasn't yet uploaded.")
      end
    end
    name = !@smf_fastlane_config[:build_variants][@smf_build_variant_sym][:podspec_path].nil? ? get_default_name_of_pod : get_default_name_of_app(build_variant)

    smf_default_build_fail_notification(build_variant: build_variant, message: message, exception: exception)
  when :android
    UI.message('Delete Hockey App for Android is not implemented yet')
    smf_default_build_fail_notification(build_variant: build_variant, message: message, exception: exception)
  when :flutter
    UI.message('Delete Hockey App for flutter is not implemented yet')
  else
    UI.message("There is no platform \"#{@platform}\", exiting...")
    raise 'Unknown platform'
  end

end
