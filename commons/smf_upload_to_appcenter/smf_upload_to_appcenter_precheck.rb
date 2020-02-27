
private_lane :smf_upload_to_appcenter_precheck do |options|
  app_name = options[:app_name]
  owner_name = options[:owner_name]
  destinations = options[:destinations]

  smf_upload_to_appcenter_precheck_destination_groups(
    app_name: app_name,
    owner_name: owner_name,
    destinations: destinations
  )

  smf_upload_to_appcenter_precheck_webhooks(
    app_name: app_name,
    owner_name: owner_name
  )
end

private_lane :smf_upload_to_appcenter_precheck_destination_groups do |options|
  app_name = options[:app_name]
  owner_name = options[:owner_name]
  destinations_array = options[:destinations].split(',')
  api_token = ENV[$SMF_APPCENTER_API_TOKEN_ENV_KEY]

  destinations_array.each do |destination_name|
    destination = Helper::AppcenterHelper.get_destination(api_token, owner_name, app_name, "group", destination_name)
    unless destination
      UI.message("App is not in destination group: #{destination_name}. Attempt to fix it...")
      if smf_appcenter_add_app_to_destination_group(app_name, owner_name, destination_name)
        UI.success("#{app_name} was added to destination group #{destination_name}")
      else
        UI.error("Failed to add #{app_name} to destination group #{destination_name}")
      end
    end
  end
end

private_lane :smf_upload_to_appcenter_precheck_webhooks do |options|
  app_name = options[:app_name]
  owner_name = options[:owner_name]

  webhookData = {
    'name' => 'SmfHub',
    'url' => $SMF_APPCENTER_WEBHOOK_URL,
    'enabled' => true,
    'event_types' => ['NewAppRelease']
  }

  webhooks = smf_appcenter_get_webhooks(app_name, owner_name)

  existingWebhook = webhooks.find { |app| app['name'] == webhookData['name'] && app['url'] == webhookData['url'] }

  if existingWebhook.nil?
    UI.message("Create Webhook: SmfHub")
    smf_appcenter_create_webhook(app_name, owner_name, webhookData)
  end
end
