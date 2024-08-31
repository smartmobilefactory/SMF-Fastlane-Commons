require 'phrase'

# LOCAL CONSTANTS
# APPLE
APPLE_LOCALE_DIR_POSTFIX = '.lproj'.freeze
APPLE_API_TOKEN_KEY = 'SMF_PHRASEAPP_ACCESS_TOKEN'.freeze
APPLE_CUSTOM_API_TOKEN_KEY = 'CUSTOM_PHRASE_APP_TOKEN'.freeze
APPLE_LOCALIZABLE_FORMAT = 'strings'.freeze

# ANDROID
ANDROID_UPLOAD_DIR_NAME = 'values'.freeze
ANDROID_UPLOAD_DIR_NAME_KMPP = 'base'.freeze
ANDROID_RESOURCE_DIR = '/app/src/main/res/'.freeze
ANDROID_RESOURCE_DIR_KMPP = '/core/src/commonMain/resources/MR/'.freeze
ANDROID_API_TOKEN_KEY = 'PHRASE_APP_TOKEN'.freeze
ANDROID_DEFAULT_LANGUAGE_KEY = 'default'.freeze
ANDROID_LOCALIZABLE_FORMAT = 'xml'.freeze
ANDROID_DEFAULT_FILE_NAME = 'strings.xml'.freeze
ANDROID_KMPP_DEFAULT_DIR = 'base'.freeze
ANDROID_DEFAULT_DIR = 'values'.freeze

# GENERAL
FILE_ENCODING = 'UTF-8'.freeze

private_lane :smf_sync_with_phrase do |options|
  # Projects phrase id
  project_id = options[:project_id]
  raise 'Unable to sync with phrase, missing project id' unless project_id

  # Optional, set to true if apple project contains custom api token
  use_custom_api_token = options[:use_custom_api_token]
  api_token = _smf_api_token(use_custom_api_token)
  upload_api_client = _smf_api_client(:upload, api_token)
  download_api_client = _smf_api_client(:download, api_token)

  is_kmpp = options[:is_kmpp]

  base = options[:base]

  if !base && [:ios, :macos, :apple].include?(@platform)
    raise 'Base is missing for Apple project'
  end

  # Base directory in which the translation files lay
  resource_dir = _smf_resource_dir(is_kmpp, options[:resource_dir])

  languages = options[:languages]
  _smf_validate_languages(languages, base)

  upload_resource_dir = _smf_get_upload_resource_dir(
    is_kmpp,
    resource_dir,
    base,
    options[:upload_resource_dir]
  )

  if options[:download_resource_dir]
    download_resource_dir = File.join(smf_workspace_dir, options[:download_resource_dir])
  else
    download_resource_dir = resource_dir
  end

  # push and pull for the main locales
  _smf_upload_and_download_translations(
    upload_api_client,
    download_api_client,
    project_id,
    upload_resource_dir,
    download_resource_dir,
    languages,
    is_kmpp,
    base
  )

  # handle extensions with seperate project ids and resources folders
  if [:ios, :macos, :apple].include?(@platform)
    extensions = options[:extensions]
    _smf_handle_apple_extensions(
      upload_api_client,
      download_api_client,
      base,
      extensions
    )
  end
end

# uploads and downloads the translation files for given resource directories and a project id
def _smf_upload_and_download_translations(upload_api_client, download_api_client, project_id, upload_resource_dir, download_resource_dir, languages, is_kmpp, base, commit_message = nil)

  used_tags = _smf_upload_translations(
    upload_api_client,
    project_id,
    upload_resource_dir,
    languages,
    base
  )

  # sleep for a small amount of time to make uploaded strings available to download again
  sleep(15)

  _smf_download_translations(
    download_api_client,
    project_id,
    download_resource_dir,
    languages,
    used_tags,
    is_kmpp
  )

  _smf_commit_changes_if_needed(download_resource_dir, commit_message)
end

def _smf_handle_apple_extensions(upload_api_client, download_api_client, base, extensions)
  return unless extensions

  UI.message('Handling extensions...')
  extensions.each do |extension|
    project_id = extension.dig(:project_id)
    resource_dir = extension.dig(:resource_dir)
    languages = extension.dig(:languages)
    next unless project_id && resource_dir && languages

    resource_dir = File.join(smf_workspace_dir, resource_dir)

    upload_resource_dir = _smf_get_upload_resource_dir(
      nil, # not needed because this is always an apple project
      resource_dir,
      base,
      nil
    )

    download_resource_dir = resource_dir

    _smf_upload_and_download_translations(
      upload_api_client,
      download_api_client,
      project_id,
      upload_resource_dir,
      download_resource_dir,
      languages,
      nil,
      base,
      'Updated strings from Phrase for extensions'
    )
  end
end

############################# API UPLOAD ############################

def _smf_upload_translations(api_client, project_id, upload_resource_dir, languages, base)
  tags = []

  Dir.foreach(upload_resource_dir) do |item|
    file = File.join(upload_resource_dir, item)

    case @platform
    when :ios, :macos, :apple
      next unless item.end_with?(APPLE_LOCALIZABLE_FORMAT)
      locale_id = languages.dig(base)

      tag = _smf_tag_from_file(item)
      tags.push(tag)

      utf8_converted_file = _smf_convert_to_utf_8_if_possible(upload_resource_dir, item)
      file = utf8_converted_file unless utf8_converted_file.nil?

      _smf_upload_translation_file(api_client, project_id, locale_id, file, tag)

      # remove file if it was a utf-8 converted copy
      if utf8_converted_file
        UI.message("Deleting #{File.basename(utf8_converted_file)}")
        File.delete(utf8_converted_file)
      end
    when :android
      next unless item.start_with?('strings')
      locale_id = languages.dig(ANDROID_DEFAULT_LANGUAGE_KEY)

      tag = _smf_tag_from_file(item)
      tags.push(tag)

      _smf_upload_translation_file(api_client, project_id, locale_id, file, tag)
    end
  end

  tags
end

def _smf_upload_translation_file(api_client, project_id, locale_id, file, tags)

  options = {
    file: File.new(file),
    locale_id: locale_id,
    tags: tags,
    update_translations: false, # REALLY important, otherwise translations might be overriden
    file_encoding: FILE_ENCODING
  }

  begin
    UI.message("Uploading translation file: #{File.basename(file)}")
    result = api_client.upload_create(project_id, File.new(file), locale_id, options)
    UI.message("Updated #{File.basename(file)} at #{result.updated_at} UTC")
  rescue Phrase::ApiError => e
    puts "Exception while uploading translation file #{file}: #{e}"
  end
end

############################# API DOWNLOAD ############################

def _smf_download_translations(api_client, project_id, download_resource_dir, languages, used_tags, is_kmpp)
  case @platform
  when :ios, :macos, :apple
    _smf_download_translations_apple(
      api_client,
      project_id,
      download_resource_dir,
      languages,
      used_tags
    )
  when :android
    _smf_download_translations_android(
      api_client,
      project_id,
      download_resource_dir,
      languages,
      used_tags.count > 1,
      is_kmpp
    )
  end
end

def _smf_download_translations_apple(api_client, project_id, download_resource_dir, languages, used_tags)
  languages.each do |language_key, locale_id|
    UI.message("Handling #{language_key} (id: #{locale_id})")

    dir = File.join(download_resource_dir, language_key + APPLE_LOCALE_DIR_POSTFIX)
    UI.message("Translation files directory is #{dir}")

    sh("mkdir -p #{dir}") # create the directory if it doesn't exit yet

    _smf_download_files_apple(
      api_client,
      project_id,
      dir,
      locale_id,
      used_tags
    )
  end
end

def _smf_download_files_apple(api_client, project_id, dir, locale_id, used_tags)
  new_files_to_download = used_tags.map { |tag| File.join(dir, tag) }

  # First update files which are already there
  Dir.foreach(dir) do |item|
    next unless item.end_with?(APPLE_LOCALIZABLE_FORMAT)

    tag = _smf_tag_from_file(item)
    output_file = File.join(dir, tag)

    new_files_to_download -= [output_file] # remove file because it was already there and will now be updated

    _smf_download_file(
      api_client,
      project_id,
      locale_id,
      output_file,
      tag,
      APPLE_LOCALIZABLE_FORMAT,
      false,
      true
    )
  end

  # if there are new files that were not there before, download them
  new_files_to_download.each do |file|
    tag = _smf_tag_from_file(file)

    _smf_download_file(
      api_client,
      project_id,
      locale_id,
      file,
      tag,
      APPLE_LOCALIZABLE_FORMAT,
      false,
      true
    )
  end
end

def _smf_download_translations_android(api_client, project_id, download_resource_dir, languages, has_multiple_translation_files, is_kmpp)
  languages.each do |language_key, locale_id|
    UI.message("Handling #{language_key} (id: #{locale_id})")

    if is_kmpp
      dir = File.join(download_resource_dir, language_key)
      if language_key == ANDROID_DEFAULT_LANGUAGE_KEY
        dir = File.join(download_resource_dir, ANDROID_KMPP_DEFAULT_DIR)
      end
    else
      dir = File.join(download_resource_dir, "values-#{language_key}")
      if language_key == ANDROID_DEFAULT_LANGUAGE_KEY
        dir = File.join(download_resource_dir, ANDROID_DEFAULT_DIR)
      end
    end

    if language_key == ANDROID_DEFAULT_LANGUAGE_KEY && has_multiple_translation_files
      _smf_download_files_android(
        api_client,
        project_id,
        dir,
        locale_id,
        is_kmpp
      )
    else
      output_file = File.join(dir, ANDROID_DEFAULT_FILE_NAME)
      sh("mkdir -p #{dir}")
      _smf_download_file(
        api_client,
        project_id,
        locale_id,
        output_file,
        nil,
        ANDROID_LOCALIZABLE_FORMAT,
        is_kmpp
      )
    end
  end
end

def _smf_download_files_android(api_client, project_id, dir, locale_id, is_kmpp)
  Dir.foreach(dir) do |item|
    next unless item.start_with?('strings')

    tag = _smf_tag_from_file(item)
    output_file = File.join(dir, "#{tag}.#{ANDROID_LOCALIZABLE_FORMAT}")

    _smf_download_file(
      api_client,
      project_id,
      locale_id,
      output_file,
      tag,
      ANDROID_LOCALIZABLE_FORMAT,
      is_kmpp
    )
  end
end

def _smf_download_file(api_client, project_id, locale_id, output_file, tags, file_format, remove_quote_escape, include_empty_translations = false)
  options = {
    return_type: 'String', # This is a workaround as there is currently no other way to get the downloaded content see https://github.com/phrase/phrase-ruby/issues/7
    file_format: file_format,
    tags: tags,
    encoding: FILE_ENCODING,
    include_empty_translations: include_empty_translations,
    format_options: { 
	    convert_placeholder: true 
    }
  }

  begin
    UI.message("Dowloading translation file #{File.basename(output_file)} with ID: #{locale_id}")
    result = api_client.locale_download(project_id, locale_id, options)
    data = result.data
    if remove_quote_escape
      UI.message("Attempting to remove escaped quotes")
      data = data.gsub('\"', '"')
    end
    File.write(output_file, data) unless result.data.nil? || result.data.empty?
  rescue Phrase::ApiError => e
    puts "Exception while downloading locale with ID #{locale_id}: #{e}"
  end
end


############################### GIT ############################

def _smf_commit_changes_if_needed(path, commit_message = nil)
  nothing_to_commit = `git status --porcelain #{path}`.empty?
  commit_message = commit_message.nil? ? 'Updated strings from Phrase' : commit_message
  if !nothing_to_commit
    git_add(path: path)
    git_commit(path: path, message: commit_message)
  end
end

############################### HELPERS #######################

# returns the correct api token based on platform and possible custom token
def _smf_api_token(use_custom_api_token)
  case @platform
  when :ios, :macos, :apple
    api_token_key = APPLE_API_TOKEN_KEY
    api_token_key = APPLE_CUSTOM_API_TOKEN_KEY if use_custom_api_token

  when :android
    api_token_key = ANDROID_API_TOKEN_KEY
  end

  api_token = ENV[api_token_key]

  raise "Phrase API token is missing! ENV key #{api_token_key}" unless api_token

  api_token
end

# initialize a donwload or uploaad api client
def _smf_api_client(type = :download, api_token)
  # Setup authorization with API token
  Phrase.configure do |config|
    config.api_key['Authorization'] = api_token
    config.api_key_prefix['Authorization'] = 'token'
  end

  case type
  when :download
    Phrase::LocalesApi.new
  when :upload
    Phrase::UploadsApi.new
  end
end

# returns the directory in which the translation files are stored
def _smf_resource_dir(is_kmpp, resource_dir)
  return File.join(smf_workspace_dir, resource_dir) if resource_dir

  case @platform
  when :ios, :macos, :apple
    raise 'Error, missing resource directory. For apple projects you have to pass a resource directory.'
  when :android
    resource_dir = File.join(smf_workspace_dir, ANDROID_RESOURCE_DIR)
    resource_dir = File.join(smf_workspace_dir, ANDROID_RESOURCE_DIR_KMPP) if is_kmpp
  end

  resource_dir
end

# returns the correct dir which contains the translation files to upload
def _smf_get_upload_resource_dir(is_kmpp, resource_dir, base, upload_resource_dir)
  return File.join(smf_workspace_dir, upload_resource_dir) if upload_resource_dir

  case @platform
  when :ios, :macos, :apple
    upload_resource_dir = File.join(resource_dir, base + APPLE_LOCALE_DIR_POSTFIX)
  when :android
    upload_resource_dir = File.join(resource_dir, ANDROID_UPLOAD_DIR_NAME)
    upload_resource_dir = File.join(resource_dir, ANDROID_UPLOAD_DIR_NAME_KMPP) if is_kmpp
  end

  upload_resource_dir
end

# assures, that the necessary languages and ids are set
def _smf_validate_languages(languages, base)
  raise 'Missing languages to translate' if !languages

  case @platform
  when :ios, :macos, :apple
    raise 'Base language is missing in languages mapping!' if !languages.dig(base)
  when :android
    raise 'default language is no set' if !languages.dig(ANDROID_DEFAULT_LANGUAGE_KEY)
  end
end

def _smf_convert_to_utf_8_if_possible(upload_resource_dir, filename)

  file_path = File.join(upload_resource_dir, filename)
  # storing the converted file temporarily in the projects root directory, will be deleted aftewards
  utf_8_converted_file_path = File.join(smf_workspace_dir, 'utf8-' + filename)

  # this returns a list of supported encodings
  supported_encodings = `iconv -l`.split(' ')
  # file -I gives information about the file and its encoding, with the gsub the encoding is extracted
  current_encoding = `file -I #{file_path}`.gsub(/.*charset=(.+)/, '\1').strip.upcase

  if !supported_encodings.include?(current_encoding)
    UI.message("Unsupported file encoding #{current_encoding}, skipping conversion!")
    return nil
  end

  UI.message("Trying to convert #{filename} from #{current_encoding} to UTF-8")

  # iconv is a tool to convert files from one encoding to another
  # this expression tries to convert the file from its current encoding to UTF-8, if it succeeds it returns 1
  result = `iconv -s --from-code=#{current_encoding} --to-code=UTF-8 #{file_path} > #{utf_8_converted_file_path} && echo "1"`.strip()

  if result == '1'
    UI.message("Successfully converted #{filename} from #{current_encoding} to UTF-8")
    return utf_8_converted_file_path
  else
    UI.message("Unabled to convert #{filename} from #{current_encoding} to UTF-8, continuing without conversion!")
    return nil
  end
end

# this function gets filename(+extension) of the whole path of a file as input
# and returns just the filename to be used as tag
def _smf_tag_from_file(file)
  case @platform
  when :ios, :macos, :apple
    # For ios the tag is the filename+extension. For example Localizable.strings
    tag = File.basename(file)
  when :android
    file_extension = ANDROID_LOCALIZABLE_FORMAT
    # For android the tag is the filename without the extension. For example, the tag for "somedir/strings.xml"
    # would be "strings"
    tag = File.basename(file, ".#{file_extension}")
  else
    raise "Unsupported platform #{@platform}"
  end

  tag
end
