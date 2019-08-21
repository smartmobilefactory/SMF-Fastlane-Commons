#######################################
### smf_disable_former_hockey_entry ###
#######################################

# options: build_variants_contains_whitelist (Hash)

desc "Disable the downlaod of the former app version on HockeyApp - does not apply for Alpha builds."
private_lane :smf_disable_former_hockey_entry do |options|

  # Parameter
  build_variants_contains_whitelist = options[:build_variants_contains_whitelist]

  # Variables
  build_variant = @smf_build_variant
  build_variant_config = @smf_fastlane_config[:build_variants][@smf_build_variant_sym]

  # Disable the download of the former non Alpha app on Hockey App
  if (!build_variants_contains_whitelist) || (build_variants_contains_whitelist.any? { |whitelist_item| build_variant.include?(whitelist_item) })
    if (Actions.lane_context[Actions::SharedValues::HOCKEY_BUILD_INFORMATION]['id'] > 1)
      previous_version_id = Actions.lane_context[Actions::SharedValues::HOCKEY_BUILD_INFORMATION]['id'] - 1

      UI.important("HERE IS THE ID OF THE Current VERSION #{Actions.lane_context[Actions::SharedValues::HOCKEY_BUILD_INFORMATION]['id']}")
      UI.important("HERE IS THE ID OF THE Previous VERSION #{previous_version_id}")

      disable_hockey_download(
          api_token: ENV[$SMF_HOCKEYAPP_API_TOKEN_ENV_KEY],
          public_identifier: build_variant_config[:hockeyapp_id],
          version_id: "#{previous_version_id}"
      )
    end
  end
end

########################################
### smf_delete_uploaded_hockey_entry ###
########################################

# options: apps_hockey_id (String)

desc "Deletes the uploaded app version on Hockey. It should be used to clean up after a error response from hockey app."
private_lane :smf_delete_uploaded_hockey_entry do |options|

  # Parameter
  apps_hockey_id = options[:apps_hockey_id]

  # Disable the download of the former non Alpha app on Hockey App
  app_version_id = Actions.lane_context[Actions::SharedValues::HOCKEY_BUILD_INFORMATION]['id']
  if (app_version_id > 1)
    UI.important("Will remove the app version with id: #{app_version_id}")

    delete_app_version_on_hockey(
        api_token: ENV[$SMF_HOCKEYAPP_API_TOKEN_ENV_KEY],
        public_identifier: apps_hockey_id,
        version_id: "#{app_version_id}"
    )
  else
    UI.message("No HOCKEY_BUILD_INFORMATION was found, so there is nothing to delete.")
  end
end