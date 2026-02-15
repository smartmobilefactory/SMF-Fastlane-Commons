require 'phrase'

# ================================================================================
# xcstrings (String Catalog) Support for Phrase
#
# This file provides sync functionality for Apple's String Catalog format (.xcstrings)
# introduced in Xcode 15 / iOS 17. Unlike traditional .strings files which require
# one file per locale, xcstrings files contain all locales in a single JSON file.
#
# Usage:
#   smf_sync_xcstrings_with_phrase(
#     xcstrings_projects: [
#       {
#         project_id: 'phrase-project-id',
#         file: 'relative/path/to/File.xcstrings',
#         source_locale: 'en',
#         locale_ids: {
#           'en' => 'phrase-locale-id-for-en',
#           'de' => 'phrase-locale-id-for-de',
#           ...
#         }
#       }
#     ]
#   )
# ================================================================================

# CONSTANTS
APPLE_STRINGS_CATALOG_FORMAT = 'strings_catalog'.freeze
XCSTRINGS_FILE_EXTENSION = '.xcstrings'.freeze
XCSTRINGS_API_TOKEN_KEY = 'PHRASEAPP_API_ACCESS_TOKEN'.freeze

# Main lane for syncing xcstrings files with Phrase
private_lane :smf_sync_xcstrings_with_phrase do |options|
  xcstrings_projects = options[:xcstrings_projects]
  raise 'Missing xcstrings_projects configuration' unless xcstrings_projects

  api_token = _smf_xcstrings_api_token
  upload_api_client = _smf_xcstrings_api_client(:upload, api_token)
  download_api_client = _smf_xcstrings_api_client(:download, api_token)

  xcstrings_projects.each do |project_config|
    _smf_sync_single_xcstrings_project(
      upload_api_client,
      download_api_client,
      project_config
    )
  end
end

# Syncs a single xcstrings project (upload + download)
def _smf_sync_single_xcstrings_project(upload_api_client, download_api_client, project_config)
  project_id = project_config[:project_id]
  file_path = project_config[:file]
  source_locale = project_config[:source_locale] || 'en'
  locale_ids = project_config[:locale_ids]

  raise "Missing project_id for xcstrings project" unless project_id
  raise "Missing file path for xcstrings project" unless file_path
  raise "Missing locale_ids mapping for xcstrings project" unless locale_ids

  full_file_path = File.join(smf_workspace_dir, file_path)
  raise "xcstrings file not found: #{full_file_path}" unless File.exist?(full_file_path)

  sync_start_time = Time.now

  UI.message("=" * 60)
  UI.message("Syncing xcstrings: #{File.basename(file_path)}")
  UI.message("Project ID: #{project_id}")
  UI.message("Source locale: #{source_locale}")
  UI.message("Locales: #{locale_ids.keys.join(', ')}")
  UI.message("=" * 60)

  # Upload the xcstrings file
  upload_duration = _smf_upload_xcstrings(
    upload_api_client,
    project_id,
    full_file_path,
    locale_ids[source_locale]
  )

  # Sleep to allow Phrase to process the upload
  sleep_duration = 5
  UI.message("Waiting #{sleep_duration} seconds for Phrase to process upload...")
  sleep(sleep_duration)

  # Download updated xcstrings with all locales
  download_duration = _smf_download_xcstrings(
    download_api_client,
    project_id,
    full_file_path,
    locale_ids[source_locale],
    locale_ids.values
  )

  # Commit changes if any
  _smf_xcstrings_commit_changes_if_needed(full_file_path)

  # Print timing summary
  total_duration = Time.now - sync_start_time
  UI.message("-" * 60)
  UI.message("Timing Summary for #{File.basename(file_path)}:")
  UI.message("  Upload:   #{upload_duration.round(2)}s")
  UI.message("  Sleep:    #{sleep_duration}s")
  UI.message("  Download: #{download_duration.round(2)}s")
  UI.message("  Total:    #{total_duration.round(2)}s")
  UI.message("-" * 60)
end

############################# UPLOAD ############################

def _smf_upload_xcstrings(api_client, project_id, file_path, source_locale_id)
  UI.message("Uploading xcstrings file: #{File.basename(file_path)}")
  start_time = Time.now

  options = {
    update_translations: true,
    file_encoding: 'UTF-8'
  }

  begin
    result = api_client.upload_create(
      project_id,
      File.new(file_path),
      APPLE_STRINGS_CATALOG_FORMAT,
      source_locale_id,
      options
    )
    duration = Time.now - start_time
    UI.success("Upload completed in #{duration.round(2)}s (server time: #{result.updated_at} UTC)")
    duration
  rescue Phrase::ApiError => e
    UI.error("Exception while uploading xcstrings file: #{e}")
    raise e
  end
end

############################# DOWNLOAD ############################

def _smf_download_xcstrings(api_client, project_id, output_file, source_locale_id, locale_ids)
  UI.message("Downloading xcstrings file with #{locale_ids.count} locales...")
  start_time = Time.now

  options = {
    return_type: 'String',
    file_format: APPLE_STRINGS_CATALOG_FORMAT,
    locale_ids: locale_ids,
    include_empty_translations: true,
    encoding: 'UTF-8'
  }

  begin
    result = api_client.locale_download(project_id, source_locale_id, options)

    if result.data.nil? || result.data.empty?
      UI.error("Downloaded xcstrings data is empty!")
      return 0
    end

    # Validate JSON before writing
    begin
      JSON.parse(result.data)
    rescue JSON::ParserError => e
      UI.error("Downloaded xcstrings is not valid JSON: #{e}")
      raise e
    end

    File.write(output_file, result.data)
    duration = Time.now - start_time
    UI.success("Downloaded xcstrings to #{File.basename(output_file)} in #{duration.round(2)}s")
    duration
  rescue Phrase::ApiError => e
    UI.error("Exception while downloading xcstrings: #{e}")
    raise e
  end
end

############################### GIT ############################

def _smf_xcstrings_commit_changes_if_needed(file_path)
  nothing_to_commit = `git status --porcelain #{file_path}`.empty?

  if nothing_to_commit
    UI.message("No changes to commit for #{File.basename(file_path)}")
    return
  end

  commit_message = 'Updated strings from Phrase'
  git_add(path: file_path)
  git_commit(path: file_path, message: commit_message)
  UI.success("Committed changes for #{File.basename(file_path)}")
end

############################### HELPERS #######################

def _smf_xcstrings_api_token
  api_token = ENV[XCSTRINGS_API_TOKEN_KEY]
  raise "Phrase API token is missing! ENV key #{XCSTRINGS_API_TOKEN_KEY}" unless api_token
  api_token
end

def _smf_xcstrings_api_client(type, api_token)
  Phrase.configure do |config|
    config.api_key['Authorization'] = api_token
    config.api_key_prefix['Authorization'] = 'token'
  end

  case type
  when :download
    Phrase::LocalesApi.new
  when :upload
    Phrase::UploadsApi.new
  else
    raise "Unknown API client type: #{type}"
  end
end
