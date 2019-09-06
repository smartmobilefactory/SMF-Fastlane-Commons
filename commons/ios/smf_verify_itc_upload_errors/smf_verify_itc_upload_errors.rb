require 'spaceship'
require 'credentials_manager'

private_lane :smf_verify_itc_upload_errors do |options|

  if options[:upload_itc] == false
    UI.message("Upload to iTunes Connect is not enabled for this project, skipping error checking.")
    next
  end

  # Parameter
  project_name = options[:project_name]
  target = options[:target]
  build_scheme = options[:build_scheme]
  itc_skip_version_check = options[:itc_skip_verison_check]
  itc_apple_id = !options[:apple_id].nil? ? options[:apple_id] : 'development@smfhq.com'
  itc_team_id = options[:itc_team_id]
  bundle_identifier = options[:bundle_identifier]

  version_number = get_version_number(
      xcodeproj: "#{project_name}.xcodeproj",
      target: !target.nil? ? target : build_scheme
  )

  build_number = get_build_number(xcodeproj: "#{project_name}.xcodeproj")

  credentials = CredentialsManager::AccountManager.new(user: itc_apple_id)

  # Setup Spaceship
  ENV[$SMF_FASTLANE_ITC_TEAM_ID_KEY] = itc_team_id
  Spaceship::Tunes.login(credentials.user, credentials.password)
  Spaceship::Tunes.select_team

  # Get the currently editable version
  app = Spaceship::Tunes::Application.find(bundle_identifier)

  # Check if there is already a build with the same build number
  versions = [version_number]
  versions.push(app.edit_version) if app.edit_version
  versions.push(app.live_version) if app.live_version

  duplicate_build_number_errors = _smf_check_if_itc_already_contains_buildnumber(app, versions, build_number)

  errors = duplicate_build_number_errors

  # Check if there is a matching editable app version
  if itc_skip_version_check != true
    no_matching_editable_app_version = _smf_check_if_app_version_is_editable_in_itc(app, version_number)
    errors = errors + no_matching_editable_app_version
  end

  Spaceship::Tunes.client = nil

  if errors.length > 0
    raise errors.join("\n")
  end
end

def _smf_check_if_itc_already_contains_buildnumber(app, version_numbers, build_number)

  errors = []

  for version in version_numbers

    UI.message("Checking if App version #{version} contains already the build number #{build_number}")

    build_trains = app.build_trains[version]
    if build_trains
      build_trains.each do |build_train|
        if build_train.build_version == build_number
          UI.error("Found matching build #{build_train.build_version}")
          errors.push("There is already a build uploaded with the build number #{build_number}. You need to increment the build number first before uploading to iTunes Connect.")
          break
        else
          UI.message("Found not matching build #{build_train.build_version}")
        end
      end
    end
  end

  return errors
end

def _smf_check_if_app_version_is_editable_in_itc(app, version_number)

  editable_app = app.edit_version

  if editable_app == nil || editable_app.version != version_number
    live_app = app.live_version
    if live_app == version_number
      error = "The current App version #{version_number} is already in sale. You need to inrement the marketing version before you can upload a new Testflight build."
    elsif editable_app != nil
      error = "The current App version #{version_number} is not editable, but #{editable_app.version} is. Please investigate why there is a mismatch."
    else
      error = "There is no editable App version #{version_number}. Please investigate why there is a mismatch."
    end

    UI.error(error)

    return [error]
  else
    UI.success("The App version #{version_number} is editable.")
    return []
  end
end