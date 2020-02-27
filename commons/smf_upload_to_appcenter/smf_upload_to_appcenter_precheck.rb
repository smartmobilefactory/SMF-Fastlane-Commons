
private_lane :smf_upload_to_appcenter_precheck do |options|
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
