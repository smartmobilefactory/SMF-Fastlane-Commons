
# Wrapper lane so android projects keep working after the newly implemented
# phrase sync lane. Should be removed as soon as all android projects are migrated.

private_lane :sync_with_phrase_app do |options|
  UI.message('⚠️⚠️⚠️️The lane/action "sync_with_phrase_app" is deprecated, please use "smf_sync_with_phrase"! ⚠️⚠️⚠️')
  smf_sync_with_phrase(options)
end