require 'phrase'

module Fastlane
  module Actions
    class SyncWithPhraseAction < Action

      # CONSTANTS
      # IOS
      IOS_LOCALE_DIR_POSTFIX = '.lproj'.freeze
      IOS_API_TOKEN_KEY = 'SMF_PHRASEAPP_ACCESS_TOKEN'.freeze
      IOS_CUSTOM_API_TOKEN_KEY = 'CUSTOM_PHRASE_APP_TOKEN'.freeze
      IOS_LOCALIZABLE_FORMAT = 'strings'.freeze

      # ANDROID
      ANDROID_UPLOAD_DIR_NAME = 'values'.freeze
      ANDROID_UPLOAD_DIR_NAME_KMPP = 'base'.freeze
      ANDROID_RESOURCE_DIR = './app/src/main/res/'.freeze
      ANDROID_RESOURCE_DIR_KMPP = './core/src/commonMain/resources/MR/'.freeze
      ANDROID_API_TOKEN_KEY = 'PHRASE_APP_TOKEN'.freeze
      ANDROID_DEFAULT_LANGUAGE_KEY = 'default'.freeze
      ANDROID_LOCALIZABLE_FORMAT = 'xml'.freeze
      ANDROID_DEFAULT_FILE_NAME = 'strings.xml'.freeze
      ANDROID_KMPP_DEFAULT_DIR = 'base'.freeze
      ANDROID_DEFAULT_DIR = 'values'.freeze

      # GENERAL
      FILE_ENCODING = 'UTF-8'.freeze


      def self.run(params)

        # Determines for which platform the sync is performed
        platform = params[:platform].to_sym

        # Projects phrase id
        project_id = params[:project_id]

        # Optional, set to true if ios project contains custom api token
        use_custom_api_token = params[:use_custom_api_token]
        api_token = api_token(platform, use_custom_api_token)
        upload_api_client = api_client(:upload, api_token)
        download_api_client = api_client(:download, api_token)

        is_kmpp = params[:is_kmpp]

        base = params[:base]
        raise 'Base is missing for iOS' if !base && platform == :ios

        # Base directory in which the translation files lay
        resource_dir = resource_dir(platform, is_kmpp, params[:resource_dir])

        languages = params[:languages]
        validate_languages(platform, languages, base)

        upload_resource_dir = params[:upload_resource_dir]
        upload_resource_dir = get_upload_resource_dir(
          platform,
          is_kmpp,
          resource_dir,
          base,
          upload_resource_dir
        )

        download_resource_dir = params[:download_resource_dir]
        download_resource_dir = resource_dir unless download_resource_dir

        # push and pull for the main locales
        upload_and_download(
          upload_api_client,
          download_api_client,
          project_id,
          platform,
          upload_resource_dir,
          download_resource_dir,
          languages,
          is_kmpp,
          base
        )

        # handle iOS extensions with seperate project ids and resources folders
        extensions = params[:extensions]
        handle_extensions(
          upload_api_client,
          download_api_client,
          platform,
          base,
          extensions
        )

      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Sync translation files with phrase"
      end

      def self.authors
        ["smf"]
      end

      def self.available_options
        [

          FastlaneCore::ConfigItem.new(key: :project_id,
                                       env_name: 'FL_PHRASE_APP_PROJECT_ID',
                                       description: "",
                                       optional: false),

          FastlaneCore::ConfigItem.new(key: :resource_dir,
                                       env_name: 'FL_PHRASE_APP_RESOURCE_DIR',
                                       description: "",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :upload_resource_dir,
                                       env_name: 'FL_PHRASE_APP_UPLOAD_RESOURCE_DIR',
                                       description: '',
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :download_resource_dir,
                                       env_name: 'FL_PHRASE_APP_DOWNLOAD_RESOURCE_DIR',
                                       description: '',
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :languages,
                                       env_name: 'FL_PHRASE_APP_LANGUAGES',
                                       type: Hash,
                                       description: 'example: {\"de\" => \"locale_id\"}',
                                       optional: false),

          FastlaneCore::ConfigItem.new(key: :is_kmpp,
                                       env_name: 'FL_PHRASE_APP_IS_KMPP',
                                       default_value: false,
                                       is_string: false,
                                       description: 'When true the naming conventions of moko/resources are used to support shared translations',
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :platform,
                                       env_name: 'FL_PHRASE_APP_PLATFORM',
                                       description: 'The platform/project type this action is ran for. Can be either :ios or :android',
                                       optional: false),

          FastlaneCore::ConfigItem.new(key: :use_custom_api_token,
                                       env_name: 'FL_PHRASE_APP_USE_CUSTOM_API_TOKEN',
                                       default_value: false,
                                       is_string: false,
                                       description: 'Set to true, if a custom phrase api token is set in the Config.json (and should be used)',
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :base,
                                       env_name: 'FL_PHRASE_APP_BASE',
                                       description: 'Required when platform is iOS. Name of the folder which cotains the translations to upload',
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :extensions,
                                       env_name: 'FL_PHRASE_APP_EXTENSIONS',
                                       type: Array,
                                       description: 'example: [  { \"project_id\" => \"abcd123ef12345abcede\, \"resource_dir\" => \"Extensions/locales\" } ]',
                                       optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:android, :ios].include? platform
      end

      private

      ############################## UPLOAD AND DOWNLOAD #################

      # uploads and downloads the translation files for given resource directories and a project id
      def self.upload_and_download(upload_api_client, download_api_client, project_id, platform, upload_resource_dir, download_resource_dir, languages, is_kmpp, base)

        used_tags = upload_translations(
          upload_api_client,
          project_id,
          platform,
          upload_resource_dir,
          languages,
          base
        )

        # sleep for a small amount of time to make uploaded strings available to download again
        sleep(15)

        download_translations(
          download_api_client,
          project_id,
          platform,
          download_resource_dir,
          languages,
          used_tags,
          is_kmpp
        )

        #commitChangesIfNeeded(download_resource_dir) # TODO: reenable
      end

      def self.handle_extensions(upload_api_client, download_api_client, platform, base, extensions)
        return unless extensions

        UI.message('Handling extensions...')
        extensions.each do |extension|
          project_id = extension.dig(:project_id)
          resource_dir = extension.dig(:resource_dir)
          languages = extension.dig(:languages)
          next unless project_id && resource_dir && languages

          upload_resource_dir = get_upload_resource_dir(
            platform,
            nil, # not needed because this is always an iOS project
            resource_dir,
            base,
            nil
          )

          download_resource_dir = resource_dir

          upload_and_download(
            upload_api_client,
            download_api_client,
            project_id,
            platform,
            upload_resource_dir,
            download_resource_dir,
            languages,
            nil,
            base
          )
        end
      end

      ############################# API UPLOAD ############################

      def self.upload_translations(api_client, project_id, platform, upload_resource_dir, languages, base)
        tags = []

        Dir.foreach(upload_resource_dir) do |item|

          case platform
          when :ios
            next unless item.end_with?(IOS_LOCALIZABLE_FORMAT)
            locale_id = languages.dig(base)
            tag = item.gsub(/(.*).#{IOS_LOCALIZABLE_FORMAT}/, '\1')
          when :android
            next unless item.start_with?('strings')
            locale_id = languages.dig(ANDROID_DEFAULT_LANGUAGE_KEY)
            tag = item.gsub(/(.*).#{ANDROID_LOCALIZABLE_FORMAT}/, '\1')
          end

          tags.push(tag)
          file = File.join(upload_resource_dir, item)

          upload_translation_file(api_client, project_id, locale_id, file, tag)
        end

        tags
      end

      def self.upload_translation_file(api_client, project_id, locale_id, file, tags)
        options = {
          file: File.new(file),
          locale_id: locale_id,
          tags: tags,
          update_translations: false, # REALLY important, otherwise translations might be overriden
          file_encoding: FILE_ENCODING
        }

        begin
          UI.message("Uploading translation file: #{file}")
          result = api_client.upload_create(project_id, options)
          UI.message("Updated #{file} at #{result.updated_at} UTC")
        rescue Phrase::ApiError => e
          puts "Exception while uploading translation file #{file}: #{e}"
        end
      end

      ############################# API DOWNLOAD ############################

      def self.download_translations(api_client, project_id, platform, download_resource_dir, languages, used_tags, is_kmpp)
        case platform
        when :ios
          download_translations_ios(
            api_client,
            project_id,
            download_resource_dir,
            languages,
            used_tags
          )
        when :android
          download_translations_android(
            api_client,
            project_id,
            download_resource_dir,
            languages,
            used_tags.count > 1,
            is_kmpp
          )
        end
      end

      def self.download_translations_ios(api_client, project_id, download_resource_dir, languages, used_tags)
        languages.each do |language_key, locale_id|
          UI.message("Handling #{language_key} (id: #{locale_id})")

          dir = File.join(download_resource_dir, language_key + IOS_LOCALE_DIR_POSTFIX)
          UI.message("Translation files directory is #{dir}")

          sh("mkdir -p #{dir}") # create the directory if it doesn't exit yet

          download_files_ios(
            api_client,
            project_id,
            dir,
            locale_id,
            used_tags
          )
        end
      end

      def self.download_files_ios(api_client, project_id, dir, locale_id, used_tags)
        files_to_download = used_tags.map { |tag| File.join(dir, tag + '.' + IOS_LOCALIZABLE_FORMAT) }

        # First update files which are already there
        Dir.foreach(dir) do |item|
          next unless item.end_with?(IOS_LOCALIZABLE_FORMAT)

          tag = item.gsub(/(.*).#{IOS_LOCALIZABLE_FORMAT}/, '\1')
          output_file = File.join(dir, tag + '.' + IOS_LOCALIZABLE_FORMAT)

          files_to_download -= [output_file] # remove file because it was already there and will now be updated

          download_file(
            api_client,
            project_id,
            locale_id,
            output_file,
            tag,
            IOS_LOCALIZABLE_FORMAT
          )
        end

        UI.message("New files to download: #{files_to_download.to_s}")

        # if there are new files that were not there before, download them
        files_to_download.each do |file|
          tag = file.gsub(/.*\/(.*).#{IOS_LOCALIZABLE_FORMAT}/, '\1')

          download_file(
            api_client,
            project_id,
            locale_id,
            file,
            tag,
            IOS_LOCALIZABLE_FORMAT
          )
        end
      end

      def self.download_translations_android(api_client, project_id, download_resource_dir, languages, has_multiple_translation_files, is_kmpp)
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
            download_files_android(
              api_client,
              project_id,
              dir,
              locale_id
            )
          else
            output_file = File.join(dir, ANDROID_DEFAULT_FILE_NAME)
            sh("mkdir -p #{dir}")
            download_file(
              api_client,
              project_id,
              locale_id,
              output_file,
              nil,
              ANDROID_LOCALIZABLE_FORMAT
            )
          end
        end
      end

      def self.download_files_android(api_client, project_id, dir, locale_id)
        Dir.foreach(dir) do |item|
          next unless item.start_with?('strings')

          tag = item.gsub(/(.*).#{ANDROID_LOCALIZABLE_FORMAT}/, '\1')
          output_file = File.join(dir, "#{tag}.#{ANDROID_LOCALIZABLE_FORMAT}")

          download_file(
            api_client,
            project_id,
            locale_id,
            output_file,
            tag,
            ANDROID_LOCALIZABLE_FORMAT
          )
        end
      end

      def self.download_file(api_client, project_id, locale_id, output_file, tags, file_format)
        options = {
          return_type: 'String', # This is a workaround as there is currently no other way to get the downloaded content see https://github.com/phrase/phrase-ruby/issues/7
          file_format: file_format,
          tags: tags,
          encoding: FILE_ENCODING
        }

        begin
          UI.message("Dowloading translation file #{output_file} with ID: #{locale_id}")
          result = api_client.locale_download(project_id, locale_id, options)
          File.write(output_file, result.data) unless result.data.nil? || result.data.empty?
        rescue Phrase::ApiError => e
          puts "Exception while downloading locale with ID #{locale_id}: #{e}"
        end
      end


      ############################### GIT ############################

      def self.commitChangesIfNeeded(path)
        nothing_to_commit = `git status --porcelain #{path}`.empty?
        if !nothing_to_commit
          other_action.git_add(path: path)
          other_action.git_commit(path: path, message: "Updated strings from PhraseApp")
        end
      end

      ############################### HELPERS #######################

      # returns the correct api token based on platform and possible custom token
      def self.api_token(platform, use_custom_api_token)
        case platform
        when :ios
          api_token_key  = IOS_API_TOKEN_KEY
          api_token_key  = IOS_CUSTOM_API_TOKEN_KEY if use_custom_api_token

        when :android
          api_token_key = ANDROID_API_TOKEN_KEY
        end

        api_token = "9ded292f47e15e6c6db3c9a09375e9c517f7cdf1526ac8c0a7c62022f2af254e" #ENV[api_token_key]

        raise "Phrase API token is missing! ENV key #{api_token_key}" unless api_token

        api_token
      end

      # initialize a donwload or uploaad api client
      def self.api_client(type = :download, api_token)
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
      def self.resource_dir(platform, is_kmpp, resource_dir)
        return resource_dir if resource_dir

        case platform
        when :ios
          raise 'Error, missing resource directory. For iOS you have to pass a resource directory.'
        when :android
          resource_dir = ANDROID_RESOURCE_DIR
          resource_dir = ANDROID_RESOURCE_DIR_KMPP if is_kmpp
        end

        resource_dir
      end

      # returns the correct dir which contains the translation files to upload
      def self.get_upload_resource_dir(platform, is_kmpp, resource_dir, base, upload_resource_dir)
        return upload_resource_dir unless !upload_resource_dir

        case platform
        when :ios
          upload_resource_dir = File.join(resource_dir, base + IOS_LOCALE_DIR_POSTFIX)
        when :android
          upload_resource_dir = File.join(resource_dir, ANDROID_UPLOAD_DIR_NAME)
          upload_resource_dir = File.join(resource_dir, ANDROID_UPLOAD_DIR_NAME_KMPP) if is_kmpp
        end

        upload_resource_dir
      end

      # assures, that the necessary languages and ids are set
      def self.validate_languages(platform, languages, base)
        raise 'Missing languages to translate' if !languages

        case platform
        when :ios
          raise 'Base language is missing in languages mapping!' if !languages.dig(base)
        when :android
          raise 'default language is no set' if !languages.dig(ANDROID_DEFAULT_LANGUAGE_KEY)
        end
      end

    end
  end
end
